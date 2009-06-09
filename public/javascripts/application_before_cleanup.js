/*

   This file is no longer used, the JavaScript way to manage
   invoice creation/edition went out of hand, and everything
   goes by Ajax now. The current application.js is light.
   
   I leave the file in the repository for reference.
   
*/

































function style_form_fields_that_cannot_be_styled_with_css_in_ie6() {
    var fine_border_bottom = function (input) {
        input.setStyle({
            borderTop:    "none",
            borderRight:  "none",
            borderBottom: "1px solid #bbb",
            borderLeft:   "none",
            color:        "#555",
            fontSize:     "12px"
        });
    };
    $$('input[type="text"]').each(fine_border_bottom);
    $$('input[type="password"]').each(fine_border_bottom);

    var fine_border = function (input) {
        input.setStyle({
            border:   "1px solid #bbb",
            color:    "#555",
            fontSize: "12px"
        });
    };
    $$('input[type="checkbox"]').each(fine_border);
    $$('input[type="submit"]').each(fine_border);
}
Event.observe(window, 'load', style_form_fields_that_cannot_be_styled_with_css_in_ie6);

function setup_tooltips() {
    $$('span.tooltip_text').each(function (e) {
       img = e.previous('img');
       new Tooltip(img.id, e.innerHTML);
    });
}
Event.observe(window, 'load', setup_tooltips);

/* Given any numeric column in the invoice body, its numbers are rendered
as integers unless they contain some float. */
function refine_format_of_numbers() {
    var invoice_lines = $('invoice-lines').rows;
    
    var amount_formatter = format_int;
    var price_formatter  = format_money_as_int;
    var totals_formatter = format_money_as_int;
    
    for (var i = 1; i < invoice_lines.length; i += 2) {
        var amount = parse_float(invoice_lines[i].cells[0].firstChild.value);
        var price  = parse_float(invoice_lines[i].cells[2].firstChild.value);
        var total  = parse_float(invoice_lines[i].cells[3].firstChild.value);
        if (is_not_integer(amount))
            amount_formatter = format_float;
        if (is_not_integer(price))
            price_formatter = format_money_as_float;
        if (is_not_integer(total))
            totals_formatter = format_money_as_float;
    }
    
    if (totals_formatter != format_float)
        ['total', 'discount', 'iva'].each(function (name) {
            var e = $('invoice-' + name);
            if (e && is_not_integer(parse_float(e.innerHTML)))
                totals_formatter = format_money_as_float;
        });
    
    for (var i = 1; i < invoice_lines.length; i += 2) {
        var amount = parse_float(invoice_lines[i].cells[0].firstChild.value);
        var price  = parse_float(invoice_lines[i].cells[2].firstChild.value);
        var total  = parse_float(invoice_lines[i].cells[3].firstChild.value);
        invoice_lines[i-1].cells[0].innerHTML = amount_formatter(amount);
        invoice_lines[i-1].cells[2].innerHTML = price_formatter(price);
        invoice_lines[i-1].cells[3].innerHTML = totals_formatter(total)
    }

    ['total', 'discount', 'iva'].each(function (name) {
        var e = $('invoice-' + name);
        if (e && /\S/.test(e.innerHTML))
            e.innerHTML = totals_formatter(parse_float(e.innerHTML));
    });
}

/* Computes the footer of the invoice and updates the totals. */
function compute_invoice_footer() {
    var invoice_lines = $('invoice-lines').rows;
    var old_discount  = $('invoice-discount').firstChild;
    var old_iva       = $('invoice-iva').firstChild;
    var old_total     = $('invoice-total').firstChild;
    
    /* if there are no lines there is no total, it is not even zero */
    if (invoice_lines.length == 0) {
        $('invoice-discount').replaceChild(document.createTextNode(""), old_discount);
        $('invoice-iva').replaceChild(document.createTextNode(""), old_iva);
        $('invoice-total').replaceChild(document.createTextNode(""), old_total);
        return;
    }

    /* otherwise we loop over the form fields to compute the total, jumping visible rows */
    var taxable = 0;
    for (var i = 1; i < invoice_lines.length; i += 2) {
        var amount = parse_float(invoice_lines[i].cells[0].firstChild.value);
        var price  = parse_float(invoice_lines[i].cells[2].firstChild.value);
        taxable += amount*price;
    }
    
    /* apply discount, if any, or else clear the discount amount */
    var discount = 0;
    var discount_percent = parse_float($F('invoice-discount-percent'));
    if (discount_percent != 0) {
        discount = taxable*discount_percent/100.0;
        /* 2212 is the Unicode code point for the minus sign, which is different from a hyphen
           in HTML we'd use &ndash;, but createTextNode() escapes character entities */
        new_discount = document.createTextNode("\u2212" + format_money(discount));
        $('invoice-discount').replaceChild(new_discount, old_discount);
    } else {
        $('invoice-discount').replaceChild(document.createTextNode(""), old_discount);
    }
    
    var iva = 0;
    var iva_percent = parse_int($F('invoice-iva-percent'));
    if (iva_percent != 0) {
        iva = taxable*iva_percent/100.0;
        new_iva = document.createTextNode(format_money(iva));
        $('invoice-iva').replaceChild(new_iva, old_iva);
        total += iva;
    } else {
        $('invoice-discount').replaceChild(document.createTextNode(""), old_iva);
    }
    
    var total = taxable - discount + iva
    var new_total = document.createTextNode(format_money(total));
    $('invoice-total').replaceChild(new_total, old_total)
    new Effect.Highlight(
        'invoice-total', {
            startcolor: "#F3F4FC", 
            endcolor:   "#C3D9FF", 
            duration:   0.3
    });
}

function cycle_invoice_lines_background() {
    var classes = ["table-row-even", "table-row-odd"];
    var invoice_lines = $('invoice-lines').rows;
    for (var i = 0; i < invoice_lines.length; i += 2) {
        invoice_lines[i].className = classes[ (i/2) % 2];
    }
}

function add_new_line_to_invoice() {
    var amount      = parse_float($F('invoice_new_line_amount'));
    var description = $F('invoice_new_line_description');
    var price       = parse_float($F('invoice_new_line_price'));
    var total       = amount*price;
    
    var data_tr = generate_invoice_data_row(amount, description, price, total);
    
    var form_tr = generate_invoice_form_row(amount, description, price, total);
    form_tr.style.display = "none";
    
    /* unfortunately Effect.Appear does not work in IE on table rows */
    $('invoice-lines').appendChild(data_tr);
    $('invoice-lines').appendChild(form_tr);
    
    compute_invoice_footer();
    refine_format_of_numbers();
    cycle_invoice_lines_background();
    
    $('invoice_new_line_amount').clear();
    $('invoice_new_line_description').clear();
    $('invoice_new_line_price').clear();
    
    $('invoice_new_line_amount').value = 1;
    $('invoice_new_line_description').focus();
    
}

function add_new_line_to_invoice_on_return(e) {
    e = e || window.event;
    if (e.keyCode == 13) {
        add_new_line_to_invoice();
        return false;
    }
    return true;
}

/* parse_int never fails _always_ returns a number */
function parse_int(str) {
    var n = parseInt(str);
    return isNaN(n) ? 0 : n;
}

function is_not_integer(n_as_float) {
    return n_as_float != Math.round(n_as_float);
}

function format_int(i) {
    var str = String(Math.round(i));
    return str.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "#{1}.");
}

function format_float(f) {
    var str = String(f);
    var dot = str.indexOf(".");
    if (dot == -1)
        str += ".00";
    else if (dot < str.length - 3)
        str = String(Math.round(f*100.0)/100.0);
    else if (dot == str.length - 2)
        str += "0";

    // based on the implementation of number_with_delimiter
    var parts = str.split('.');
    parts[0] = parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "#{1}.");
    return parts.join(",");
}

/* It mimicks FacturagemUtils.parse_decimal */
function parse_float(n) {    
    // prototype.js 1.5.1 introduces blank(), but this is 1.5.0
    if (!/\S/.test(n)) {
        return 0.0;
    }

    // remove everything that cannot be part of a number, as currency symbols
    n = n.gsub(/[^.,\d]/, '');

    // it is has no comma just delegate to parseFloat
    if (n.indexOf(",") == -1) {
        var f = parseFloat(n);
        return isNaN(f) ? 0.0 : f;
    }

    // if it has a comma, but no dot, assume it is a decimal separator
    if (n.indexOf(".") == -1) {
        var f = parseFloat(n.gsub(",", "."));
        return isNaN(f) ? 0.0 : f;
    }
    
    // if we get here it has both a comman and a dot, strip whitespace
    n = n.strip();
    
    // take sign and delete it, if any
    var s = n.charAt(0) == "-" ? -1 : 1;
    n = n.sub(/^[-+]/, '');    
    
    // we assume a dot or comma followed by zero or up to two digits at the
    // end of the string is the decimal part
    var d = "0";
    var dregexp = /[.,](\d*)$/;
    if (dregexp.exec(n)) {
        d = RegExp.$1;
        n = n.sub(dregexp, '');
    }
    
    // in what remains, which is taken as the integer part, any non-digit is
    // simply ignored
    n = n.gsub(/\D/, '');
    
    // done
    var f = s*parseFloat(n + "." + d);
    return isNaN(f) ? 0.0 : f;
}

function format_money_as_float(mnt) {
    return format_float(mnt) + " €";
}

function format_money_as_int(mnt) {
    return format_int(mnt) + " €";
}

var format_money = format_money_as_float;

function generate_invoice_data_row(amount, description, price, total) {
    var amount_td = document.createElement("td");
    amount_td.className = "num";
    amount_td.appendChild(document.createTextNode(format_float(amount)));

    var description_td = document.createElement("td");
    description_td.appendChild(document.createTextNode(description));

    var price_td = document.createElement("td");
    price_td.className = "num";
    price_td.appendChild(document.createTextNode(format_money(price)));

    var total_td = document.createElement("td");
    total_td.className = "num";
    total_td.appendChild(document.createTextNode(format_money(total)));

    var actions_td = document.createElement("td");
    actions_td.className = "actions";
    action_edit = document.createElement('a');
    action_edit.onclick = function () { edit_invoice_line(this); return false; };
    action_edit.href = "#";
    action_edit.appendChild(document.createTextNode("Corregir"));
    actions_td.appendChild(action_edit);
    
    actions_td.appendChild(document.createTextNode(" | "));
    
    action_remove = document.createElement('a');
    action_remove.onclick = function () { remove_invoice_line(this); return false; };
    action_remove.href = "#";
    action_remove.appendChild(document.createTextNode("Borrar"));
    actions_td.appendChild(action_remove);
    
    data_tr = document.createElement("tr");
    data_tr.appendChild(amount_td);
    data_tr.appendChild(description_td);
    data_tr.appendChild(price_td);
    data_tr.appendChild(total_td);
    data_tr.appendChild(actions_td);
    
    return data_tr;
}

/* Generates a hidden table row with the form behind each visible invoice row. */
function generate_invoice_form_row(amount, description, price, total) {
    var amount_td = document.createElement('td');
    var amount_input = document.createElement("input");
    amount_input.type = 'text';
    amount_input.setAttribute("name", "amount[]");
    amount_input.setAttribute("value", amount);
    amount_td.appendChild(amount_input);

    var description_td = document.createElement('td');
    var description_input = document.createElement("input");
    description_input.type = 'text';
    description_input.setAttribute("name", "description[]");
    description_input.setAttribute("value", description);
    description_td.appendChild(description_input);
    
    var price_td = document.createElement('td');
    var price_input = document.createElement("input");
    price_input.type = 'text';
    price_input.setAttribute("name", "price[]");
    price_input.setAttribute("value", price);
    price_td.appendChild(price_input);

    var total_td = document.createElement('td');
    var total_input = document.createElement("input");
    total_input.type = 'text';
    total_input.setAttribute("name", "total[]");
    total_input.setAttribute("value", total);
    total_td.appendChild(total_input);

    var form_tr = document.createElement('tr');
    form_tr.appendChild(amount_td);
    form_tr.appendChild(description_td);
    form_tr.appendChild(price_td);
    form_tr.appendChild(total_td);
    
    return form_tr;
}

/* Removes the invoice line to which the received cell belongs. */
function remove_invoice_line(cell) {
    var data_tr = Element.extend(cell).up('tr');
    var form_tr = data_tr.next('tr');
    form_tr.remove();
    data_tr.remove();
    
    cycle_invoice_lines_background();
    compute_invoice_footer();
    refine_format_of_numbers();
}

/* Puts the data of this line back into the form and deletes the line itself. */
function edit_invoice_line(cell) {
    var data_tr = Element.extend(cell).up('tr');
    var form_tr = data_tr.next('tr');
    $('invoice_new_line_amount').value      = $F(form_tr.down('td', 0).down('input'));
    $('invoice_new_line_description').value = $F(form_tr.down('td', 1).down('input'));
    $('invoice_new_line_price').value       = $F(form_tr.down('td', 2).down('input'));
    
    remove_invoice_line(cell);

    $('invoice_new_line_amount').activate();
}

/* A convenience method that triggers footer computation on return. */
function compute_invoice_footer_on_return(e) {
    e = e || window.event;
    if (e.keyCode == 13) {
        compute_invoice_footer();
        return false;
    }
    return true;
}