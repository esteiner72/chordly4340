class ChordSheet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :chord_sheets_set_list, dependent: :destroy
  has_many :set_lists, through: :chord_sheets_set_list

  validates :name, presence: true
  validates :content, presence: true

  has_paper_trail limit: 15

  scope :not_deleted, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }

  def transpose(direction)
    content.map! do |line_hash|
      line = SheetLine.new(line_hash)
      next(line) unless line.chords?

      line.transpose(direction)
    end
    self
  end

  CHORD_TOKEN_RE = /\A[A-G][#b]?(?:m(?:aj)?\d*|sus\d*|dim|aug)?(?:\/[A-G])?\z/

  def to_chordpro
    lines = content.map { |h| h["content"].rstrip }

    lines.reject! { |l| l.strip =~ /\A\[[^\]]+\]\z/ }

    pro = []
    pro << "# #{name}"
    pro << ""
    pro << "{title: #{name}}"
    pro << ""

    i = 0
    in_section = nil

    while i < lines.size
      line = lines[i].strip

      if cap = line[/\ACapo\s+(\d+)\z/,1]
        pro << "{capo: #{cap}}"
        pro << ""
        i += 1
        next
      end

      if chord_line?(line) && next_is_lyric?(lines, i)
        pro << inline_chord_line(line, lines[i+1])
        i += 2
        next
      end
      pro << line unless line.empty?
      i += 1
    end

    pro.reject! { |l| l =~ /\A\{(?:start_of|end_of)_[^}]+\}/ }
    pro.join("\n")
  end

  def chord_line?(line)
    tokens = line.split
    tokens.any? && tokens.all? { |t| t.match?(CHORD_TOKEN_RE) }
  end

  def next_is_lyric?(rows, idx)
    return false if idx + 1 >= rows.size
    next_line = rows[idx + 1].strip

    !chord_line?(next_line) && next_line.match?(/[a-z,.’]/i)
  end

  def inline_chord_line(chord_row, lyric_row)
    chords = chord_row.split(/\s+/)
    words  = lyric_row.strip.split(/\s+/)
    result = []
    i = 0

    words.each do |w|
      if chords[i]
        result << "[#{chords[i]}]#{w}"
        i += 1
      else
        result << w
      end
    end
    line = result.join(" ")
    line = line.sub(/\A\[[^\]]+\]/, "").lstrip
    line = line.gsub(/\[\]/, "").squeeze(" ").rstrip
    line
  end

  def unique_chords
    chord_lines = content.select { |line| line["type"] == "chords" }
    chord_lines.flat_map { |line| line["content"].split }.uniq
  end
end
