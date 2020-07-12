
class Slide {


  static get toolbox() {
    return {
      title: 'Slide',
      icon: '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 36 32"><path d="M34 4h-2v-2c0-1.1-0.9-2-2-2h-28c-1.1 0-2 0.9-2 2v24c0 1.1 0.9 2 2 2h2v2c0 1.1 0.9 2 2 2h28c1.1 0 2-0.9 2-2v-24c0-1.1-0.9-2-2-2zM4 6v20h-1.996c-0.001-0.001-0.003-0.002-0.004-0.004v-23.993c0.001-0.001 0.002-0.003 0.004-0.004h27.993c0.001 0.001 0.003 0.002 0.004 0.004v1.996h-24c-1.1 0-2 0.9-2 2v0zM34 29.996c-0.001 0.001-0.002 0.003-0.004 0.004h-27.993c-0.001-0.001-0.003-0.002-0.004-0.004v-23.993c0.001-0.001 0.002-0.003 0.004-0.004h27.993c0.001 0.001 0.003 0.002 0.004 0.004v23.993z"></path><path d="M30 11c0 1.657-1.343 3-3 3s-3-1.343-3-3 1.343-3 3-3 3 1.343 3 3z"></path><path d="M32 28h-24v-4l7-12 8 10h2l7-6z"></path></svg>'
    };
  }
  constructor({data}){
    const chars = [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
    this.imageId = [...Array(6)].map(i=>chars[Math.random()*chars.length|0]).join``;
    this.data = data;
    if(this.data.header == null)
    {
      var tmpData = { //image/header/text/link/link_text
        header: "Slide Title",
        text: "Slightly longer slide header text, simply click on any item to change.",
        link: "/index.xml",
        link_text: "Some mushrooms...",
        image: "/images/mushrooms.jpg"
      };
      this.data = tmpData;
    }
    //alert("Data: "+JSON.stringify(data));
  }


  render(){

    const imgId = this.imageId;

    this.wrapper = document.createElement('div');
    const ibutton = document.createElement("button");
    ibutton.style = "float: right;";
    ibutton.innerHTML = "...";
    this.wrapper.appendChild(ibutton);
    this.wrapper.id = this.imageId;
    //alert("in render banner");
    this.wrapper.classList.add("slide");
    this.wrapper.classList.add("slide_c");
    this.wrapper.style = "background: url("+this.data.image+") no-repeat 0px 0px;";

    const slide_up = document.createElement('div');
    slide_up.classList.add("slider-up");
    this.header = document.createElement('h4');
    this.header.innerHTML = this.data.header;
    this.header.setAttribute("contenteditable", "true");

    this.header_text = document.createElement('h5');
    this.header_text.innerHTML = this.data.text;
    this.header_text.setAttribute("contenteditable", "true");
    slide_up.appendChild(this.header);
    slide_up.appendChild(this.header_text);

    this.more_button = document.createElement('div');
    this.more_button.classList.add("more_button");
    this.more_button.setAttribute("contenteditable", "true");

    this.link = document.createElement('a');
    this.link.href = this.data.link;
    this.link.innerHTML = this.data.link_text;
    this.link.setAttribute("contenteditable", "true");
    this.more_button.appendChild(this.link);
    slide_up.appendChild(this.more_button);
    this.wrapper.appendChild(slide_up);

    const slide_image = document.createElement('div');
    slide_image.classList.add("slide_image");
    this.wrapper.appendChild(slide_image);


    ibutton.onclick = function(){
      //alert("hello");
      //if(w2ui.hasOwnProperty('popsidebar')){ w2ui['popsidebar'].destroy(); }
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
                    "       $('#"+imgId+"').attr('style',\'background: url('+selectedFile+') no-repeat 0px 0px;\');"+
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

    }

    return this.wrapper;
  }

  save(blockContent){
    var my_image = this.wrapper.style.backgroundImage;
    my_image = my_image.substring(5, my_image.lastIndexOf("\""));

    var toRet = {
      header: this.header.innerHTML,
      text: this.header_text.innerHTML,
      link: this.link.href,
      link_text: this.link.innerHTML,
      image: my_image
    }
    //alert(JSON.stringify(toRet));
    return toRet;
  }
}
