function add_list(payload)
{
    var vposition = payload.position;
    var list = "<ul class='app'>";
    var velements = payload.items;
    if (typeof payload.items === "string")
    {
      velements = jQuery.parseJSON(payload.items);
    }
    $.each(velements, function( index, value ) {
      list += "<li>"+value+"</li>";
    });
    list += "</ul>"
    return list;
}
