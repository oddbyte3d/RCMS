function add_rcmsimage(value)
{
  var path = value.path;
  var position = value.position;
  var title = value.title;
  var alt_attribute = value.alt_attribute;
  var border = value.border;
  var rounded = value.rounded;
  var popup_picture = value.popup_picture;
  var popup_title = value.popup_title;
  var popup_alt_attribute = value.popup_alt_attribute;
  var link_target = value.link_target;
  var link_url = value.link_url;
  var classes = "";
  if(border) classes+="img_border ";
  if(rounded) classes+="img_rounded ";
  return "<img src=\""+mydomain+path+"\" class=\""+classes+"\" >"
}
