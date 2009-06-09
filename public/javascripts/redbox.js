
var RedBox = {

  showInline: function(id)
  {
    this.showOverlay();
    new Effect.Appear('RB_window', {duration: 0.4, queue: 'end'});        
    this.cloneWindowContents(id);
  },

  loading: function()
  {
    this.showOverlay();
    Element.show('RB_loading');
    this.setWindowPosition();
  },

  addHiddenContent: function(id)
  {
    this.removeChildrenFromNode($('RB_window'));
    this.moveChildren($(id), $('RB_window'));
    Element.hide('RB_loading');
    new Effect.Appear('RB_window', {duration: 0.4, queue: 'end'});  
    this.setWindowPosition();
  },

  close: function()
  {
    new Effect.Fade('RB_window', {duration: 0.4});
    new Effect.Fade('RB_overlay', {duration: 0.4});
    this.showSelectBoxes();
  },

  showOverlay: function()
  {
    if ($('RB_redbox'))
    {
      Element.update('RB_redbox', "");
      new Insertion.Top($('RB_redbox'), '<div id="RB_window" style="display: none;"></div><div id="RB_overlay" style="display: none;"></div>');  
    }
    else
    {
      new Insertion.Top(document.body, '<div id="RB_redbox" align="center"><div id="RB_window" style="display: none;"></div><div id="RB_overlay" style="display: none;"></div></div>');      
    }
    new Insertion.Bottom('RB_redbox', '<div id="RB_loading" style="display: none"></div>');  

    this.setOverlaySize();
    this.hideSelectBoxes();
    new Effect.Appear('RB_overlay', {duration: 0.4, to: 0.6, queue: 'end'});
  },

  setOverlaySize: function()
  {
    if (window.innerHeight && window.scrollMaxY >= 0)
    {  
      yScroll = window.innerHeight + window.scrollMaxY;
    } 
    else if (document.body.scrollHeight > document.body.offsetHeight)
    { // all but Explorer Mac
      yScroll = document.body.scrollHeight;
    }
    else
    { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
      yScroll = document.body.offsetHeight;
    }
    $("RB_overlay").style['height'] = yScroll +"px";
  },

  setWindowPosition: function()
  {
    var pagesize = this.getPageSize();  
  
    $("RB_window").style['width'] = 'auto';
    $("RB_window").style['height'] = 'auto';

    var dimensions = Element.getDimensions($("RB_window"));
    var width = dimensions.width;
    var height = dimensions.height;        
    
    $("RB_window").style['left'] = ((pagesize[0] - width)/2) + "px";
    $("RB_window").style['top'] = ((pagesize[1] - height)/2) + "px";
  },


  getPageSize: function() {
    var de = document.documentElement;
    var w = window.innerWidth || self.innerWidth || (de&&de.clientWidth) || document.body.clientWidth;
    var h = window.innerHeight || self.innerHeight || (de&&de.clientHeight) || document.body.clientHeight;
  
    arrayPageSize = new Array(w,h) 
    return arrayPageSize;
  },

  removeChildrenFromNode: function(node)
  {
    while (node.hasChildNodes())
    {
      node.removeChild(node.firstChild);
    }
  },

  moveChildren: function(source, destination)
  {
    while (source.hasChildNodes())
    {
      destination.appendChild(source.firstChild);
    }
  },

  cloneWindowContents: function(id)
  {
    /* Patched by fxn: Remove IDs below in descendants of the
    RedBox container to avoid collisions in the clone. */
    var content = $(id);
    content.descendants().each(function (d) {
       d.removeAttribute("id"); 
    });
    
    var cloned_content = $(content.cloneNode(true));
    
    /* Patched by fxn: IE does not preserve selections in cloned
    combos due to a bug documented here:
    
      http://support.microsoft.com/kb/829907
      
    As a workaround we copy the selected indices by hand. */
    if (!!(window.attachEvent && !window.opera)) {
        var selects = content.getElementsByTagName('SELECT');
        var cloned_selects = cloned_content.getElementsByTagName('SELECT');
        for (var i = 0; i < selects.length; ++i)
          cloned_selects[i].selectedIndex = selects[i].selectedIndex;
    }

    cloned_content.style['display'] = 'block';
    $('RB_window').appendChild(cloned_content);

    this.setWindowPosition();
  },
  
  hideSelectBoxes: function()
  {
    $$('select').each(function (s) {
        if (!s.hasClassName('in-redbox'))
            s.hide();
    });
  },
              
  showSelectBoxes: function()
  {
    $$('select').each(function (s) {
        if (!s.hasClassName('in-redbox'))
            s.show();
    });
  }



}