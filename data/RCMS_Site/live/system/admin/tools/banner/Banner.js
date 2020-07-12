
class Banner {


  static get toolbox() {
    return {
      title: 'Banner',
      icon: '<svg width="17" height="15" viewBox="0 0 336 276" xmlns="http://www.w3.org/2000/svg"><path d="M291 150V79c0-19-15-34-34-34H79c-19 0-34 15-34 34v42l67-44 81 72 56-29 42 30zm0 52l-43-30-56 30-81-67-66 39v23c0 19 15 34 34 34h178c17 0 31-13 34-29zM79 0h178c44 0 79 35 79 79v118c0 44-35 79-79 79H79c-44 0-79-35-79-79V79C0 35 35 0 79 0z"/></svg>'
    };
  }
  constructor({data}){
    const chars = [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
    this.imageId = [...Array(6)].map(i=>chars[Math.random()*chars.length|0]).join``;
    this.data = data;
    if(this.data.header_title == null)
    {
      var tmpData = {
        header_title: "Title",
        header_text: "Slightly longer header text, simply click on any item to change.",
        banner_text: "Aenean ornare velit lacus, ac varius enim ullamcorper eu. Proin aliquam facilisis ante interdum congue. Integer mollis, nisl amet convallis, porttitor magna ullamcorper, amet egestas mauris. Ut magna finibus nisi nec lacinia. Nam maximus erat id euismod egestas. Pellentesque sapien ac quam. Lorem ipsum dolor sit nullam.",
        image: "/images/mushrooms.jpg",
        image_alt: "Some mushrooms...",
        items: [
            { action: "Action...", action_text: "Link Text"}
        ]
      };
      this.data = tmpData;
    }
    //alert("Data: "+JSON.stringify(data));
  }


  render(){

    const wrapper = document.createElement('section');
    //alert("in render banner");
    wrapper.classList.add("banner");

    const content = document.createElement('div');
    content.classList.add("content");
    const header = document.createElement('header');
    this.h_header_title = document.createElement('h1');
    //alert(this.data.header_title);
    this.h_header_title.innerHTML = this.data.header_title;
    this.h_header_title.setAttribute("contenteditable", "true");
    this.p_header_text = document.createElement('p');
    this.p_header_text.innerHTML = this.data.header_text;
    this.p_header_text.setAttribute("contenteditable", "true");

    header.appendChild(this.h_header_title);
    header.appendChild(this.p_header_text);
    content.appendChild(header);

    this.p_banner_text = document.createElement('p');
    this.p_banner_text.innerHTML = this.data.banner_text;
    this.p_banner_text.setAttribute("contenteditable", "true");
    content.appendChild(this.p_banner_text);

    const ul_actions = document.createElement('ul');
    ul_actions.id = "actions";
    ul_actions.classList.add("actions");

    this.a = document.createElement("a");
    this.a.setAttribute("contenteditable", "true");
    const atest = this.a;
    //alert("Items: "+JSON.stringify(this.data.items));
    $.each(this.data.items, function( index, value ) {
      //<a href="<%=action_item["action"]%>" class="button big"><%=action_item["action_text"]%></a>
      var li = document.createElement("li");

      atest.classList.add("button");
      atest.classList.add("big");
      atest.href = value.action;
      atest.innerHTML = value.action_text;
      li.appendChild(atest);
      ul_actions.appendChild(li);
    });
    content.appendChild(ul_actions);
    wrapper.appendChild(content);
    var span = document.createElement("span");
    span.classList.add("image");
    span.classList.add("object");
    this.img = document.createElement("img");
    this.img.id = this.imageId;
    //alert("Setting image Id :"+img.id);
    this.img.src = this.data.image;
    this.img.alt = this.data.image_alt;
    span.appendChild(this.img);
    wrapper.appendChild(span);

    this.img.classList.add("img_hover");
    //alert(this.imageId);
    const myImg = this.img;
    this.img.onclick = function(){
      //alert("hello");
      //if(w2ui.hasOwnProperty('popsidebar')){ w2ui['popsidebar'].destroy(); }
      //var myImg = this.img;
      w2popup.open({
          width   : 680,
          height  : 500,
          title   : 'File Selector',
          body    : "<div style='height: 710px; width: 510px;'><div id='popsidebar' style='float: left; height: 250px; width: 200px;'>"+
                    "<script src='/system/admin/js/RFS.js'></script>"+
                    " <script type='text/javascript'>"+
                    "    var selectedFile = null;"+
                    "    function selectFile(file){"+
                    "       selectedFile = file;"+
                    "       $('#preview').html('<img style=\"height: 250px; width: 400px;\" src=\"'+file+'\"/>');"+
                    "     }"+
                    "     var fileSel = selectFile;"+
                    "     function clickOk(){"+
                    "       $('#"+myImg.id+"').attr('src',\''+selectedFile+'\');"+
                    "     }"+
                    "     if(w2ui.hasOwnProperty('popsidebar')){ w2ui['popsidebar'].destroy(); }"+
                    "    $('#popsidebar').w2sidebar({"+
                    "       name: 'popsidebar',"+
                    "       nodes: ["+
                  	"       	{ id: 'content-folder', text: 'Content', img: 'icon-folder', expanded: true, group: true,"+
                  	"       	  nodes: [ { id: 'pages', text: 'Assets', img: 'icon-page'} ]"+
                  	"       	}"+
                  	"       ],"+
                  	"       onClick: function (event) {"+
                    "           processRFSClick(event, 'jpg,jpeg,gif,png', fileSel);"+
                  	"       }"+
                    "       });"+
                    "   setSideBar(w2ui.popsidebar);"+
                    "   w2ui['popsidebar'].click('pages');"+
                    "</script></div><div id='preview' style='float: right; height: 250px; width: 300px;'></div></div>",
          buttons : '<button class="w2ui-btn" onclick="clickOk(); w2popup.close();">Ok</button>'+
                    '<button class="w2ui-btn" onclick="w2popup.close()">Cancel</button>'
      });

                //eval(code);
    }
    //alert(wrapper);
    return wrapper;
  }

  save(blockContent){

    var toRet = {
      header_title: this.h_header_title.innerHTML,
      header_text: this.p_header_text.innerHTML,
      banner_text: this.p_banner_text.innerHTML,
      image: this.img.src,
      image_alt: this.img.alt,
      items: [
          { action: this.a.href, action_text: this.a.innerHTML}
      ]
    }
    //alert(JSON.stringify(toRet));
    return toRet;
  }
}
