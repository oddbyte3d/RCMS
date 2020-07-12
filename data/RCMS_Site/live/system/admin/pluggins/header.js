function add_header(value)
{
  //alert("--->"+JSON.stringify(payloa));
    var title = value.title;
    var facebook = value.facebook;
    var twitter = value.twitter;
    var linkedin = value.linkedin;
    var instagram = value.instagram;
    //alert("hello....");
    var insert = "<header id=\"header\">"+
                 "<a href=\"#\" class=\"logo\"><strong>"+title+"</strong></a>"+
                 "<ul class=\"icons\">";
    if(twitter){
        insert += "<li><a href=\"tw_link\" class=\"icon brands fa-twitter\"><span class=\"label\">Twitter</span></a></li>";
    }
    if(facebook){
        insert += "<li><a href=\"tw_link\" class=\"icon brands fa-facebook-f\"><span class=\"label\">Facebook</span></a></li>";
    }
    if(linkedin){
        insert += "<li><a href=\"tw_link\" class=\"icon brands fa-linkedin\"><span class=\"label\">LinkedIn</span></a></li>";
    }
    if(instagram){
        insert += "<li><a href=\"tw_link\" class=\"icon brands fa-instagram\"><span class=\"label\">Instagram</span></a></li>";
    }
    insert += "</ul></header>";
    //alert("Returning::: "+insert);
    return insert;

}
