
class RCMSImage {

  static get toolbox() {
    return {
      title: 'RCMS Image',
      icon: '<svg width="17" height="15" viewBox="0 0 336 276" xmlns="http://www.w3.org/2000/svg"><path d="M291 150V79c0-19-15-34-34-34H79c-19 0-34 15-34 34v42l67-44 81 72 56-29 42 30zm0 52l-43-30-56 30-81-67-66 39v23c0 19 15 34 34 34h178c17 0 31-13 34-29zM79 0h178c44 0 79 35 79 79v118c0 44-35 79-79 79H79c-44 0-79-35-79-79V79C0 35 35 0 79 0z"/></svg>'
    };
  }
  constructor({data}){
    const chars = [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
    this.imageId = [...Array(6)].map(i=>chars[Math.random()*chars.length|0]).join``;
    this.data = data;
  }



  render(){
    const wrapper = document.createElement('div');
    const img = document.createElement('img');
    const imgId = this.imageId;
    img.id = this.imageId;
    //alert(this.data.rounded);

    if(this.data.rounded)
    {
      img.classList.add("img_rounded");
    }
    if(this.data.border)
    {
      img.classList.add("img_border");
    }
    img.classList.add("img_hover");
    //alert(this.imageId);

    img.onclick = function(){
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
                    "       $('#"+imgId+"').attr('src',\''+selectedFile+'\');"+
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

    img.src = this.data.path;
    wrapper.classList.add('rcmsimage');
    wrapper.appendChild(img);
    //wrapper.appendChild(input);
    //var element = document.getElementById(this.imageId);

    //input.placeholder = 'Paste an image URL...';
    //input.value = this.data && this.data.path ? this.data.path : '';

    return wrapper;
  }

  save(blockContent){
    //const img = $('#rcmsimg');//blockContent.querySelector('input');

    return {
      path: $('#'+this.imageId+'').attr('src'),//input.value,
      position: "left",
      title: "",
      alt_attribute: "",
      border: "false",
      rounded: "true",
      popup_picture: "",
      popup_title: "",
      popup_alt_attribute: "",
      link_target: "",
      link_url: ""
    }
  }
}



//                    "         else if(event.target.startsWith('file'))"+
//                    "         {"+
//                    "           var file = event.target;"+
//                    "         }"+
//                    "         else"+
//                    "         {"+
//                    "           //alert(fileSystem);"+
//                    "         }"+
