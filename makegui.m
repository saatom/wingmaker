%Wyatt Richards <wr1701@proton.me>
function h = makegui(configname)
  close all;
  pkg load io;
  h.fig = figure;

  if ~exist(".wingmakerrc") %make a settings file if one doesn't already exist
    fid=fopen(".wingmakerrc", 'w');
    fputs(fid, "theme, 1\n");
    fputs(fid, "scale, 1\n");
    fputs(fid, "meshlines, 1\n");
    fputs(fid, "meshpoints, 50\n");
    fclose(fid);
  endif

  guiprefs=csv2cell(".wingmakerrc"); %import preferences from a file
  for i=1:size(guiprefs)(1)
    param = guiprefs{i,1};
    val = guiprefs{i,2};
    if isnumeric(val)
      val = num2str(val); %make numeric settings into strings
    endif
    eval(["h." param " = " val ";"]);
  endfor

  wing = loadwingdata(configname, h.meshpoints);

  if h.theme == 1 %dark theme
    c.button = [40, 44, 48]/255; %button background color
    c.border = [71, 75, 77]/255;
    c.background = [27, 31, 34]/255; %panel background color
    c.background_text = [19, 22, 24]/255;
    c.panel = [31, 35, 38]/255; %panel background color
    %c.background=c.background_text;
    c.text = [1 1 1];
    c.axis = c.border;
    c.background_plot = c.panel;
  else %eye scorcher theme
    c.button = [220, 220, 220]/255; %button background color
    c.border = [205, 205, 205]/255;
    c.background = [255, 255, 255]/255; %panel background color
    c.background_text = [200, 200, 200]/255;
    c.panel = [239, 239, 239]/255; %panel background color
    %c.background=c.background_text;
    c.text = [0 0 0];
    c.axis = [0 0 0];
    c.background_plot = [1 1 1];
  endif
  uiscale = 1;

  set(h.fig, "color", c.background, "sizechangedfcn", @updatePlot);
  set(groot, 
  "defaultuipanelbackgroundcolor", c.panel,
  "defaultuipanelhighlightcolor", c.border,

  "defaultuibuttongroupbackgroundcolor", c.panel,
  "defaultuibuttongrouphighlightcolor", c.border,

  "defaultuicontrolunits", "normalized",
  "defaultuicontrolfontunits", "normalized",
  "defaultuicontrolfontsize", .6,	
  "defaultuicontrolhorizontalalignment", "center",	
  "defaultuicontrolforegroundcolor", c.text,
  "defaultuicontrolbackgroundcolor", c.button);

  h.panel2 = uipanel ("units", "pixels", "position", [0 0 1 1], "backgroundcolor", c.background);
  h.panel1 = uipanel ("units", "pixels", "position", [0 0 300 640]);
  h.group1 = uibuttongroup (h.panel1, "position", [0 .9 1 .1]); %main button group
  h.infogroup = uibuttongroup (h.panel1, "position", [0 .08 1 .3], "visible", false); %info group
  p.button={"parent", h.panel1,
  "units", "normalized", 
  "string", "Another Button", 
  "backgroundcolor", c.button,
  "foregroundcolor", c.text};
  h.performance_button = uicontrol ("parent", h.group1,
  "string", "Calculate Performance",
  "style", "pushbutton",
  "callback", @updatePlot,
  "position",[0  0 1 .5]);
  h.theme_button = uicontrol ("parent", h.group1, 
  "string", ["Theme: " {"light", "dark"}{h.theme+1}], 
  "callback", @updatePlot,
  "style", "pushbutton",
  "position",[0 .5 1 .5]);
  h.slider_text = uicontrol ("style", "text",
  "parent", h.panel1, 
  "position", [0 .04 .5 .04],
  "backgroundcolor", c.panel,
  "string", "Alpha: ");

  %% START INFO GROUP

  infocount = 6;
  h.lift_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "position", [0 (1/infocount)*(3-1) 1 1/infocount],
  "horizontalalignment", "left",
  "backgroundcolor", c.panel,
  "string", "L: (NO DATA) N");
  h.drag_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "position", [0 (1/infocount)*(2-1) 1 1/infocount],
  "horizontalalignment", "left",
  "backgroundcolor", c.panel,
  "string", "D: (NO DATA) N");
  h.moment_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "position", [0 (1/infocount)*(1-1) 1 1/infocount],
  "horizontalalignment", "left",
  "backgroundcolor", c.panel,
  "string", "M (c/4): (NO DATA) Nm");
  h.velocity_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "horizontalalignment", "left",
  "position", [0 (1/infocount)*(4-1) 1 1/infocount],
  "backgroundcolor", c.panel,
  "string", "V_∞: 50 m/s");
  h.altitude_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "position", [0 (1/infocount)*(5-1) 1 1/infocount],
  "horizontalalignment", "left",
  "backgroundcolor", c.panel,
  "string", "Altitude: 0 km");
  h.alpha_l0_text = uicontrol ("style", "text", "parent", h.infogroup, 
  "position", [0 (1/infocount)*(6-1) 1 1/infocount],
  "horizontalalignment", "left",
  "backgroundcolor", c.panel,
  "string", "Alpha_L=0: (NO DATA) deg");

  %% END INFO GROUP

  h.slider_text_entry = uicontrol ("style", "edit",
  "parent", h.panel1, 
  "units", "normalized", 
  "horizontalalignment", "left",
  "backgroundcolor", c.background_text,
  "position", [.5 .04 .5 .04],
  "fontunits", "normalized",
  "callback", @updatePlot,
  %"callback", @(x, a) set(h.alpha_slider, "value", str2num(get(x, "value"))),
  "string", "0");
  h.alpha_slider = uicontrol (
  "style", "slider", 
  "string", "Alpha slider", 
  %"callback", @(x, a) set(h.slider_text_entry, "string", num2str(get(x, "value"))),
  "callback", @updatePlot,
  "parent", h.panel1, 
  "units", "normalized", 
  "position",[0 0 1 .04], 
  "sliderstep", [1 .15], 
  "min", -12, 
  "max", 12, 
  "value", 0);

  h.ax = axes("parent", h.panel2);
  %h.plot=plot(h.ax, [2 3], [2 3]);
  wing.yy_plot = [fliplr(wing.yy), -wing.yy];
  wing.xx_plot = [fliplr(wing.xx), wing.xx];
  wing.zz_plot = [fliplr(wing.zz), wing.zz];
  h.wing=wing;
  h.plot = surf(h.ax, wing.xx_plot, wing.yy_plot, wing.zz_plot);
  shading interp;
  if h.meshlines == 1
    set(h.plot, "edgecolor", "k");
  endif
  daspect([1 1 1]);
  axis tight
  set(gca, "xcolor", c.axis, "ycolor", c.axis, "zcolor", c.axis, "color", c.background_plot);
  guidata(gcf, h);
  %h.colorbar=colorbar("parent", h.plot);
endfunction

function changerc(prop, val)
  guiprefs = csv2cell(".wingmakerrc");
  for i=1:size(guiprefs)(1)
    if strcmpi(guiprefs{i,1}, prop)
      guiprefs{i,2}=val;
      name=make_absolute_filename(".wingmakerrc");
      cell2csv(name, guiprefs);
      break;
    endif
  endfor
endfunction

function updatePlot(obj, init = false)
  replot = false;
  h=guidata(obj);
  wing=h.wing;

  function out = alphaFilter(in, rnd)
    %global wing;
    if in < wing.alphas(1)
      out=wing.alphas(1);
    elseif in > wing.alphas(2)
      out=wing.alphas(2);
    else
      if rnd == false
	out = in
      else
	out=round(in/wing.alphas(3))*wing.alphas(3);
      endif
    endif
  endfunction

  function resizeUI()
    panel_ar=.4; %aspect ratio of the useful panel
    %panel_max_height=get(0, 'screensize')(4)*2/3;
    panel_max_height=get(0, 'screensize')(4);
    newsize=get(h.fig, "position")(3:4);
    panelsize=get(h.panel1, "position")(3:4);
    newpanelsize=[panel_ar*min([newsize(2) panel_max_height]) min([newsize(2) panel_max_height])];
    set(h.panel1, "position", [newsize-newpanelsize newpanelsize]);
    set(h.panel2, "position", [0 0 newsize(1)-newpanelsize(1) newsize(2)]);
  endfunction

  switch obj
    case h.alpha_slider
      alpha=alphaFilter(get(h.alpha_slider, "value"), true);
      set(h.slider_text_entry, "string", num2str(alpha));
      replot = true;
    case h.slider_text_entry
      alpha=alphaFilter(str2num(get(h.slider_text_entry, "string")),  false);
      set(h.slider_text_entry, "string", num2str(alpha));
      set(h.alpha_slider, "value", alpha);
      replot = true;
    case h.performance_button
      disp("requesting performance")
      %h.wing.alphas = [-5 5 1];
      h.wing.performance_data = performance(wing, 50, wing.alphas, 0);
      set(h.alpha_slider, "min", wing.alphas(1), "max", wing.alphas(2), "value", 0);
      set(h.slider_text_entry, "string", "0");
      guidata(gcf, h);
      set(h.alpha_l0_text, "string", sprintf("Alpha_L=0: %.2f deg", h.wing.performance_data.alpha_l0));
      alpha = 0;
      replot = true;
    case h.fig
      resizeUI();
    case h.theme_button
      changerc("theme", ~h.theme);
      makegui(h.wing);
  endswitch	    
  if replot
    wing=h.wing;
    if size(wing.performance_data.polar) > 0
      pol=wing.performance_data.polar;
      %lin=find(pol(:,1)==alpha);
      %data=pol(lin, 2:5);
      data=[];
      for i=2:5
	data=[data interp1(pol(:,1), pol(:,i), alpha)];
      endfor

      L=sprintf("%.1f", data(1));
      D=sprintf("%.1f", data(2)+data(3));
      M=sprintf("%.1f", data(4));
      set(h.lift_text, "string", ["L: " L " N"]);
      set(h.drag_text, "string", ["D: " D " N"]);
      set(h.moment_text, "string", ["M (c/4): " M " Nm"]);
      set(h.infogroup, "visible", true);
    endif
    set(h.plot, "xdata", wing.xx_plot.*cosd(-alpha) - wing.zz_plot.*sind(-alpha),
    "zdata", wing.xx_plot.*sind(-alpha) + wing.zz_plot.*cosd(-alpha));
    axis tight
  endif
endfunction
