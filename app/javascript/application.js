// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import '@fortawesome/fontawesome-free/js/fontawesome.js'
import '@fortawesome/fontawesome-free/js/solid.js'
import '@fortawesome/fontawesome-free/js/regular.js'
import '@fortawesome/fontawesome-free/js/brands.js'
import "trix"
import "@rails/actiontext"
import LocalTime from "local-time"
  
LocalTime.start()

document.addEventListener("DOMContentLoaded", () => {
    console.log("JavaScript loaded");
    const buttons = document.querySelectorAll("#transpose-up, #transpose-down");
    
    if (buttons.length === 0) {
      console.error("No buttons found with IDs #transpose-up or #transpose-down");
      return;
    }
    console.log(`Found ${buttons.length} buttons`);
  
    buttons.forEach(button => {
      console.log(`Attaching click listener to ${button.id}`);
      button.addEventListener("click", (event) => {
        console.log(`Button clicked: ${button.id}`);
        event.preventDefault();
        
        const form = button.closest("form");
        if (!form) {
          console.error("No form found for button:", button.id);
          return;
        }
        console.log("Form action:", form.action);
  
        const semitonesSelect = document.querySelector(button.dataset.semitones);
        if (!semitonesSelect) {
          console.error("Semitones select not found:", button.dataset.semitones);
          return;
        }
        const semitonesValue = semitonesSelect.value;
        console.log(`Semitones value: ${semitonesValue}`);
  
        let input = form.querySelector("input[name='semitones']");
        if (!input) {
          input = document.createElement("input");
          input.type = "hidden";
          input.name = "semitones";
          form.appendChild(input);
        }
        input.value = semitonesValue;
        console.log("Submitting form with semitones:", semitonesValue);
        form.submit();
      });
    });
  });