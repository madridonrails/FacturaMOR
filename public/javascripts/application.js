function add_underlines() {
    // Input text fields share a class through all the application
    // except the ones in table cells, which have class TableUnderline.
    // We put the class in the code for those, and assign the class
    // dynamically for the rest to DRY the HTML.
    var fine_border_bottom = function (input) {
        var re = /underline/i; // underline, TableUnderline, TableUnderlineR
        if (!re.test(input.className)) {
            input.addClassName("underline");
        }
    };
    $$('input[type="text"]').each(fine_border_bottom);
    $$('input[type="password"]').each(fine_border_bottom);
}
Event.observe(window, 'load', add_underlines);

/*
  We turn autocompletion off in all text fields so that numbers,
  dates, invoice numbers, etc. do not interfere. This gives a clean
  data entry experience. Nevertheless, some text fields do want to
  have autocompletion on, and in that case they say so adding a class
  "autocomplete".

  We do not use the "autocomplete" attribute in source code because
  it is not in the standard and gives warnings in HTML validators.
*/
function turn_autocomplete_off() {
    $$('input[type="text"]').each(function (e) {
        if (!e.hasClassName('autocomplete'))
            e.setAttribute("autocomplete", "off");
    });
}
Event.observe(window, 'load', turn_autocomplete_off);

function set_default_maxlength() {
    var set_maxlength = function (input) {
        if (input.maxLength == -1)
            input.maxLength = 255;        
    }
    $$('input[type="text"]').each(set_maxlength);
    $$('input[type="password"]').each(set_maxlength);
}
Event.observe(window, 'load', set_default_maxlength);

function ignore_newline(event) {
    var e = event || window.event;
    return e.keyCode == Event.KEY_RETURN ? false : true;
}

function add_new_line_to_invoice_on_return(e) {
    e = e || window.event;
    if (e.keyCode == Event.KEY_RETURN) {
        new Ajax.Request('/invoices/add_new_line', {asynchronous:true, evalScripts:true, parameters:Form.serialize('invoice-form')});
        return false;
    }
    return true;
}

function edit_invoice_header() {
    Effect.Fade('header-edition-switcher');
    Effect.Fade('invoice-header-left-show');
    Effect.Fade('invoice-header-right-show');
    Effect.Appear('invoice-header-left-edit', {queue: 'end'});
    Effect.Appear('invoice-header-right-edit', {queue: 'end'});
}

function check_acceptance_of_terms_of_service(f) {
    if (f.accept_terms_of_service.checked) return true;
    alert("Para completar el registro debe aceptar las condiciones del servicio.");
    return false;
}

/* Dynamically adjusts the size of a text-field to more or less fit its content, minimum size 3. */
function autofit(input) {
    input.size = Math.max(input.value.length+2, 5);
}

function check_availability_of_short_name(input) {
    new Ajax.Request('/public/check_availability_of_short_name', {asynchronous:true, evalScripts:true, parameters:"short_name=" + input.value});
}

/*
  If the users cancels creation errors shouldn't be there if he
  decides to pop up the form again later.
*/
function clean_errors_in_customer_redbox() {
    var re = /^errors_for_customer_/;
    $$('span.error').each(function (span) {
       if (span.id && re.test(span.id))
         span.update('');
    });
}

/* This test has been copied from prototype.js */
function explorer() {
    return (/MSIE/.test(navigator.userAgent) && !window.opera);
}

/* To be triggered when the date picker is shown. */
function hide_customer_selector_if_explorer() {
    if (explorer())
        $('invoice_customer_id').hide();
}

/* To be triggered when the date picker gets closed. */
function show_customer_selector_if_explorer() {
    if (explorer())
        $('invoice_customer_id').show();
}
