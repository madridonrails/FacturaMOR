/**
 * DatePicker widget using Prototype and Scriptaculous.
 * (c) 2007 Mathieu Jondet <mathieu@eulerian.com>
 * Eulerian Technologies
 *
 * DatePicker is freely distributable under the same terms as Prototype.
 *
 */

var DatePicker	= Class.create();

DatePicker.prototype	= {
 Version	: '0.9.2',
 _relative	: null,
 _div		: null,
 _zindex	: 1,
 _keepFieldEmpty: false,
 _daysInMonth	: [31,28,31,30,31,30,31,31,30,31,30,31],
 /* language */
 _language	: 'fr',
 _language_month	: $H({
  'fr'	: [ 'Janvier', 'F&#233;vrier', 'Mars', 'Avril', 'Mai', 'Juin', 
   'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'D&#233;cembre' ],
  'en'	: [ 'January', 'February', 'March', 'April', 'May',
   'June', 'July', 'August', 'September', 'October', 'November', 'December' ],
  'sp'	: [ 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
   'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre' ],
  'it'	: [ 'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
   'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre' ],
  'de'	: [ 'Januar', 'Februar', 'M&#228;rz', 'April', 'Mai', 'Juni',
   'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember' ],
  'pt'	: [ 'Janeiro', 'Fevereiro', 'Mar&#231;o', 'Abril', 'Maio', 'Junho',
   'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro' ]
 }),
 _language_day	: $H({
  'fr'	: [ 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim' ],
  'en'	: [ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ],
  'sp'	: [ 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'S&#224;b', 'Dom' ],
  'it'	: [ 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom' ],
  'de'	: [ 'Mon', 'Die', 'Mit', 'Don', 'Fre', 'Sam', 'Son' ],
  'pt'	: [ 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'S&#225;', 'Dom' ]
 }),
 _language_close	: $H({
  'fr'	: 'fermer',
  'en'	: 'close',
  'sp'	: 'cierre',
  'it'	: 'fine',
  'de'	: 'schliessen',
  'pt'	: 'fim'
 }),
 /* date manipulation */
 _todayDate	: new Date(),
 _date_regexp	: /^(\d{1,2})(\/|\.|\-)(\d{1,2})(?:\/|\.|\-)(\d{4})$/,
 _current_date	: null,
 _clickCallback	: Prototype.emptyFunction,
 _closeCallback : Prototype.emptyFunction, /* fxn */
 _date_separator: '/',
 _id_datepicker	: null,
 /* positionning */
 _topOffset	: 30,
 _leftOffset	: 0,
 _isPositionned	: false,
 _relativePosition : true,
 /* return the name of current month in appropriate language */
 getMonthLocale	: function ( month ) {
  return	this._language_month[this._language][month];
 },
 getLocaleClose	: function () {
  return	this._language_close[this._language];
 },
 _initCurrentDate : function () {
  /* check if value in field is proper, set to today */
  this._current_date	= $F(this._relative);
  if ( !this._date_regexp.test(this._current_date) ) {
   var now	= new Date();
   var day	= this._leftpad_zero(now.getDate(), 2);
   var mon	= this._leftpad_zero(now.getMonth() + 1, 2);
   /* depending on language not presented the same way */
   if ( this._language == 'en' )
    this._current_date	= mon+'/'+day+'/'+now.getFullYear();
   else 
    this._current_date	= day+'/'+mon+'/'+now.getFullYear();
   /* set the field value ? */
   if ( !this._keepFieldEmpty )
    $(this._relative).setAttribute('value', this._current_date);
  }
  var a_date_regexp	= this._current_date.match(this._date_regexp);
  /* fetch date separator as specified in option or via value */
  this._date_separator	= String(a_date_regexp[2]);
  /* check language */
  if ( this._language == 'en' ) {
   this._current_mon	= Number(a_date_regexp[1]) - 1;
   this._current_day	= Number(a_date_regexp[3]);
  } else {
   this._current_day	= Number(a_date_regexp[1]);
   this._current_mon	= Number(a_date_regexp[3]) - 1;
  }
  this._current_year	= Number(a_date_regexp[4]);
 },
 /* init */
 initialize	: function ( h_p ) {
  /* arguments */
  this._relative= h_p["relative"];
  if ( h_p["language"] )
   this._language = h_p["language"];
  this._zindex	= ( h_p["zindex"] ) ? parseInt(Number(h_p["zindex"])) : 1;
  if ( typeof(h_p["keepFieldEmpty"]) != 'undefined' )
   this._keepFieldEmpty	= h_p["keepFieldEmpty"];
  if ( typeof(h_p["clickCallback"]) == 'function' )
   this._clickCallback	= h_p["clickCallback"];
  if ( typeof(h_p["closeCallback"]) == 'function' ) /* fxn */
   this._closeCallback	= h_p["closeCallback"];
  if ( typeof(h_p["leftOffset"]) != 'undefined' )
   this._leftOffset	= parseInt(h_p["leftOffset"]);
  if ( typeof(h_p["topOffset"]) != 'undefined' )
   this._topOffset	= parseInt(h_p["topOffset"]);
  if ( typeof(h_p["relativePosition"]) != 'undefined' )
   this._relativePosition = h_p["relativePosition"];
  this._id_datepicker		= 'datepicker-'+this._relative;
  this._id_datepicker_prev	= this._id_datepicker+'-prev';
  this._id_datepicker_next	= this._id_datepicker+'-next';
  this._id_datepicker_hdr	= this._id_datepicker+'-header';
  this._id_datepicker_ftr	= this._id_datepicker+'-footer';

  /* build up calendar skel */
  this._div = Builder.node('div', { 
    id 		: this._id_datepicker,
    className	: 'datepicker',
    style	: 'display: none; z-index: '+this._zindex 
   }, [
      /* header */
      Builder.node('div', { className : 'datepicker-header' }, [
       Builder.node('span', { 
	id : this._id_datepicker_prev, style : 'cursor: pointer;' }, ' << '),
       Builder.node('span', { id : this._id_datepicker_hdr }),
       Builder.node('span', { 
	id : this._id_datepicker_next, style : 'cursor: pointer;' }, ' >> ')
      ]),
      /* calendar */
      Builder.node('div', { className : 'datepicker-calendar' }, [
       Builder.node('table', { id : this._id_datepicker+'-table' }) ]),
      /* footer */
      Builder.node('div', { 
       id 	: this._id_datepicker_ftr,
       className: 'datepicker-footer' }, this.getLocaleClose() )
  ]);
  /* finally declare the event listener on input field */
  Event.observe(this._relative, 
    'click', this.click.bindAsEventListener(this), false);
  /* need to append on body when doc is loaded for IE */
  Event.observe(window, 'load', this.load.bindAsEventListener(this), false);
 },
 /**
  * load	: called when document is fully-loaded to append datepicker
  *		  to main object.
  */
 load		: function () {
  /* append to body */
  var body	= document.getElementsByTagName("body").item(0);
  if ( body )
   body.appendChild( this._div );
  /* init the date in field if needed */
  this._initCurrentDate();
  /* declare the observers for UI control */
  Event.observe($(this._id_datepicker_prev), 
    'click', this.prevMonth.bindAsEventListener(this), false);
  Event.observe($(this._id_datepicker_next), 
    'click', this.nextMonth.bindAsEventListener(this), false);
  Event.observe($(this._id_datepicker_ftr), 
    'click', this.close.bindAsEventListener(this), false);
 },
 /**
  * click	: called when input element is clicked
  */
 click		: function () {
  if ( !this._isPositionned && this._relativePosition ) {
   /* position the datepicker relatively to element */
   var a_lt = Position.positionedOffset($(this._relative));
   $(this._id_datepicker).setStyle({
    'left'	: Number(a_lt[0]+this._leftOffset)+'px',
    'top'	: Number(a_lt[1]+this._topOffset)+'px'
   });
   this._isPositionned	= true;
  }
  if ( !$(this._id_datepicker).visible() ) {
   this._initCurrentDate();
   this._redrawCalendar();
  }
  /* eval the clickCallback function */
  eval(this._clickCallback());
  /* Effect toggle to fade-in / fade-out the datepicker */
  new Effect.toggle(this._id_datepicker, 'appear');
 },
 /**
  * close	: called when the datepicker is closed
  */
 close		: function () {
  new Effect.Fade(this._id_datepicker, { duration : 0.3 });
  eval(this._closeCallback()); /* fxn */
 },
 /**
  * setPosition	: set the position of the datepicker.
  *  param : t=top | l=left
  */
 setPosition	: function ( t, l ) {
  var h_pos	= { 'top' : '0px', 'left' : '0px' };
  if ( typeof(t) != 'undefined' )
   h_pos['top']	= Number(t)+this._topOffset+'px';
  if ( typeof(l) != 'undefined' )
   h_pos['left']= Number(l)+this._leftOffset+'px';
  $(this._id_datepicker).setStyle(h_pos);
  this._isPositionned	= true;
 },
 /**
  * _leftpad_zero : pad the provided string to given number of 0
  */
  /** CHECK toPaddedString: from http://dev.rubyonrails.org/changeset/6363 */
 _leftpad_zero	: function ( str, padToLength ) {
  var result	= '';
  for ( var i = 0; i < (padToLength - String(str).length); i++ )
   result	+= '0';
  return	result + str;
 },
 /**
  * _getMonthDays : given the year and month find the number of days.
  */
 _getMonthDays	: function ( year, month ) {
  if (((0 == (year%4)) && 
   ( (0 != (year%100)) || (0 == (year%400)))) && (month == 1))
   return 29;
  return this._daysInMonth[month];
 },
 /**
  * _buildCalendar	: draw the days array for current date
  */
 _buildCalendar		: function () {
  var _self	= this;
  var tbody	= document.createElement('tbody');
  /* generate day headers */
  var trDay	= document.createElement('tr');
  this._language_day[this._language].each( function ( item ) {
   var td	= document.createElement('td');
   td.innerHTML	= item;
   td.className	= 'wday';
   trDay.appendChild( td );
  });
  tbody.appendChild( trDay );
  /* generate the content of days */
  
  /* build-up days matrix */
  var a_d	= [
    [ 0, 0, 0, 0, 0, 0, 0 ]
   ,[ 0, 0, 0, 0, 0, 0, 0 ]
   ,[ 0, 0, 0, 0, 0, 0, 0 ]
   ,[ 0, 0, 0, 0, 0, 0, 0 ]
   ,[ 0, 0, 0, 0, 0, 0, 0 ]
   ,[ 0, 0, 0, 0, 0, 0, 0 ]
  ];
  /* set date at beginning of month to display */
  var d		= new Date(this._current_year, this._current_mon, 1, 12);
  /* start the day list on monday */
  var startIndex	= ( !d.getDay() ) ? 6 : d.getDay() - 1;
  var nbDaysInMonth	= this._getMonthDays(
    this._current_year, this._current_mon);
  var daysIndex		= 1;
  for ( var j = startIndex; j < 7; j++ ) {
   a_d[0][j]	= { 
     d : daysIndex
    ,m : this._current_mon
    ,y : this._current_year 
   };
   daysIndex++;
  }
  var a_prevMY	= this._prevMonthYear();
  var nbDaysInMonthPrev	= this._getMonthDays(a_prevMY[1], a_prevMY[0]);
  for ( var j = 0; j < startIndex; j++ ) {
   a_d[0][j]	= { 
     d : Number(nbDaysInMonthPrev - startIndex + j + 1) 
    ,m : Number(a_prevMY[0])
    ,y : a_prevMY[1]
    ,c : 'outbound'
   };
  }
  var switchNextMonth	= false;
  var currentMonth	= this._current_mon;
  var currentYear	= this._current_year;
  for ( var i = 1; i < 6; i++ ) {
   for ( var j = 0; j < 7; j++ ) {
    a_d[i][j]	= { 
      d : daysIndex
     ,m : currentMonth
     ,y : currentYear
     ,c : ( switchNextMonth ) ? 'outbound' : ( 
      ((daysIndex == this._todayDate.getDate()) &&
        (this._current_mon  == this._todayDate.getMonth()) &&
        (this._current_year == this._todayDate.getFullYear())) ? 'today' : null)
    };
    daysIndex++;
    /* if at the end of the month : reset counter */
    if ( daysIndex > nbDaysInMonth ) {
     daysIndex	= 1;
     switchNextMonth = true;
     if ( this._current_mon + 1 > 11 ) {
      currentMonth = 0;
      currentYear += 1;
     } else {
      currentMonth += 1;
     }
    }
   }
  }

  /* generate days for current date */
  for ( var i = 0; i < 6; i++ ) {
   var tr	= document.createElement('tr');
   for ( var j = 0; j < 7; j++ ) {
    var h_ij	= a_d[i][j];
    var td	= document.createElement('td');
    /* id is : datepicker-day-mon-year or depending on language other way */
    /* don't forget to add 1 on month for proper formmatting */
    if ( this._language == 'en' ) 
     var id	= $A([ this._relative, this._leftpad_zero((h_ij["m"] +1), 2),
       this._leftpad_zero(h_ij["d"], 2), h_ij["y"] ]).join('-');
     else 
      var id	= $A([ this._relative, this._leftpad_zero(h_ij["d"], 2),
	this._leftpad_zero((h_ij["m"] + 1), 2), h_ij["y"] ]).join('-');
    /* set id and classname for cell if exists */
    td.setAttribute('id', id);
    if ( h_ij["c"] )
     td.className	= h_ij["c"];
    /* on onclick : rebuild date value from id of current cell */
    td.onclick	= function () { 
     $(_self._relative).value = String($(this).readAttribute('id')
	).replace(_self._relative+'-','').replace(/-/g,_self._date_separator); 
     _self.close(); 
    };
    td.innerHTML= h_ij["d"];
    tr.appendChild( td );
   }
   tbody.appendChild( tr );
  }
  return	tbody;
 },
 /**
  * nextMonth	: redraw the calendar content for next month.
  */
 _nextMonthYear	: function () {
  var c_mon	= this._current_mon;
  var c_year	= this._current_year;
  if ( c_mon + 1 > 11 ) {
   c_mon	= 0;
   c_year	+= 1;
  } else {
   c_mon	+= 1;
  }
  return	[ c_mon, c_year ];
 },
 nextMonth	: function () {
  var a_next		= this._nextMonthYear();
  this._current_mon	= a_next[0];
  this._current_year 	= a_next[1];
  this._redrawCalendar();
 },
 /**
  * prevMonth	: redraw the calendar content for previous month.
  */
 _prevMonthYear	: function () {
  var c_mon	= this._current_mon;
  var c_year	= this._current_year;
  if ( c_mon - 1 < 0 ) {
   c_mon	= 11;
   c_year	-= 1;
  } else {
   c_mon	-= 1;
  }
  return	[ c_mon, c_year ];
 },
 prevMonth	: function () {
  var a_prev		= this._prevMonthYear();
  this._current_mon	= a_prev[0];
  this._current_year 	= a_prev[1];
  this._redrawCalendar();
 },
 _redrawCalendar	: function () {
  this._setLocaleHdr();
  var table	= $(this._id_datepicker+'-table');
  try {
   while ( table.hasChildNodes() )
    table.removeChild(table.childNodes[0]);
  } catch ( e ) {}
  table.appendChild( this._buildCalendar() );
 },
 _setLocaleHdr	: function () {
  /* next link */
  var a_next	= this._nextMonthYear();
  $(this._id_datepicker_next).setAttribute('title',
   this.getMonthLocale(a_next[0])+' '+a_next[1]);
  /* prev link */
  var a_prev	= this._prevMonthYear();
  $(this._id_datepicker_prev).setAttribute('title',
   this.getMonthLocale(a_prev[0])+' '+a_prev[1]);
  /* header */
  $(this._id_datepicker_hdr).update('&nbsp;&nbsp;&nbsp;'+this.getMonthLocale(this._current_mon)+'&nbsp;'+this._current_year+'&nbsp;&nbsp;&nbsp;');
 }
};
