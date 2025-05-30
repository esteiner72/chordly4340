class ChordSheetsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[create show transpose update download_chordpro]
  before_action :authorize_user, only: %i[show transpose update destroy versions restore download_chordpro]
  before_action :adjust_new_lines, only: %i[create]

  def index
    @chord_sheets = current_user.chord_sheets.not_deleted.order(build_order_query(:chord_sheet))
    @set_lists = current_user.set_lists.not_deleted.order(build_order_query(:set_list))
  end

  def show
    @chord_sheet = ChordSheet.find(params[:id])
    @columns     = params[:columns].to_i
    @columns     = 1 unless [1,2].include?(@columns)
    respond_to do |format|
      format.html
      format.pdf do
        html = render_to_string(layout: "application")
        send_data Grover.new(html).to_pdf, filename: "#{@chord_sheet.name}.pdf", type: "application/pdf", locals: { columns: @columns }
      end
    end
  end

  def new
    @chord_sheet = ChordSheet.new
  end

  def create
    @chord_sheet = ChordSheet.new(chord_sheet_params)
    if @chord_sheet.save
      redirect_to @chord_sheet
    else
      flash.now[:alert] = "Failed to create chord sheet: #{@chord_sheet.errors.full_messages.join(', ')}"
      respond_to { |format| format.turbo_stream }
    end
  end

  def transpose
    semitones = params[:semitones].to_i
    direction = params[:direction]

    Rails.logger.debug "Transposing: semitones=#{semitones}, direction=#{direction}"

    if semitones > 0 && %w[up down].include?(direction)
      semitones.times {
        if !@chord_sheet.transpose(direction).save
          flash[:alert] = "Failed to transpose chord sheet: #{@chord_sheet.errors.full_messages.join(', ')}"
          render :show, status: :unprocessable_entity
          return
        end
      }
      flash[:notice] = "Chord sheet transposed by #{semitones} semitone#{semitones == 1 ? '' : 's'} #{direction}."
      redirect_to @chord_sheet
    else
      flash[:alert] = "No transposition applied: semitones=#{semitones.inspect}, direction=#{direction.inspect}"
      render :show
    end
  end

  def update
    if @chord_sheet.update(chord_sheet_params)
      flash.now[:notice] = "Changes saved"
    else
      flash.now[:alert] = "Failed to update chord sheet: #{@chord_sheet.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @chord_sheet.update(deleted: true)
    flash[:notice] = "Chord sheet deleted"
    redirect_to chord_sheets_path
  end

  def versions; end

  def restore
    version = @chord_sheet.versions.find(params[:version_id])
    version.reify.save
    redirect_to @chord_sheet
  end

  def download_chordpro
    respond_to do |format|
      format.text do
        send_data @chord_sheet.to_chordpro,
                  filename: "#{@chord_sheet.name}.pro",
                  type: "text/plain; charset=utf-8"
      end
    end
  end

  private

  def chord_sheet_params
    params.require(:chord_sheet).permit(:name, :content, :trial, :trial_user_id).tap do |p|
      p[:content] = ChordSheetModeller.new(p[:content]).parse if p[:content]
      p[:user] = current_user
    end
  end

  def adjust_new_lines
    params[:chord_sheet][:content] = params[:chord_sheet][:content].gsub("\n", "\r\n")
  end

  def build_order_query(resource)
    return { created_at: :desc } unless params["#{resource}_order"]

    { name: params["#{resource}_order"] }
  end

  def authorize_user
    @chord_sheet = ChordSheet.find(params[:id])
    authorize(@chord_sheet)
  end
end
