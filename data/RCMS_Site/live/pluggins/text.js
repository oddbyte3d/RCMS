function add_text(value)
{
  var bold = value.bold;
  var italic = value.italic;
  var underlined = value.underlined;
  var textcolor = value.color;
  var textsize = value.size;
  var align = value.alignment;
  var visible = value.visible;
  var printtext = value.printtext;
  return "<p align=\""+align+"\">"+printtext+"</p>";
}
