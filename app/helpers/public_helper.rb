module PublicHelper
  # This helper is used in the help, it is just a reload without anchor.
  def ir_al_principio
    link_to 'Ir al principio'
  end
  
  def date_una_vuelta_o_registrate
    return <<-HTML
    <div class="TextHighlightOrange" style="width: 50%; margin-left: auto; margin-right: auto; margin-top: 30px">
      #{link_to 'Date una vuelta', :controller => 'tour'}
      o
      #{link_to 'Regístrate gratis', :controller => 'public', :action => 'signup'}
  	</div>
    HTML
  end

  def registrate_gratis
    return <<-HTML
    <div class="TextHighlightOrange" style="width: 30%; margin-left: auto; margin-right: auto; margin-top: 30px">
      #{link_to 'Regístrate gratis', :controller => 'public', :action => 'signup'}
  	</div>
    HTML
  end
  
  def help_answer_separator
    '<div class="help-answer-separator"></div>'
  end
end
