function add_banner(payload)
{

    var header_title = payload.header_title;
    var header_text = payload.header_text;
    var banner_text = payload.banner_text;
    var image = payload.image;
    var image_alt = payload.image_alt;
    //alert("Type:: "+(typeof payload.items));
    var velements = payload.items;
    if (typeof payload.items === "string")
    {
      velements = jQuery.parseJSON(payload.items);
    }
    //alert("Calling Banner ::: "+velements);
    var insert = "<section id=\"banner\">"+
                 "<div class=\"content\"><header><h1>"+header_title+"</h1>"+
                 "<p>"+header_text+"</p></header><p>"+banner_text+"</p>"+
                 "<ul class=\"actions\">";

     $.each(velements, function( index, value ) {
       insert += "<li><a href=\""+value["action"]+"\">"+value["action_text"]+"</a></li>";
     });

    insert += "</ul></div><span class=\"image object\"><img src=\""+mydomain+image+"\" alt=\""+image_alt+"\" /></span></section> ";
    //$('#pagecontent').prepend(insert);
    return insert;
}
