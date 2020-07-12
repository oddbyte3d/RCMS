var myGridArea = null;
var myGridDetailArea = null;
var selectedId = null;
var subscriptionData = null;
function setGridArea(mygridarea)
{
  myGridArea = mygridarea;
}

function setGridDetailArea(mygriddetailarea)
{
  myGridDetailArea = mygriddetailarea;
}

function createListGrid()
{
      $().w2grid({
          name: 'sublist',
          show: {
              toolbar: true,
              footer: true,
              toolbarAdd: true,
              toolbarDelete: true,
              toolbarSave: true,
              lineNumbers    : true,
              toolbarEdit: false
          },
          menu: [
              { id: 1, text: 'Select Item', icon: 'fa-star' },
              { id: 2, text: 'View Item', icon: 'fa-camera' },
              { id: 4, text: 'Delete Item', icon: 'fa-minus' }
          ],
          searches: [
              { field: 'subname', caption: 'Subscription Queue', type: 'text' }
          ],
          columns: [
              //{ field: 'recid', caption: 'ID', size: '50px', sortable: true, attr: 'align=center' },
              { field: 'subname', caption: 'Subscription Queue', size: '95%', sortable: true },
              { field: 'subcount', caption: 'Subscribed', size: '95%', sortable: true }
          ],
          onAdd: function (event) {
              //w2alert('add');
              w2prompt({
                  label       : 'Enter Queue Name',
                  value       : '',
                  attrs       : 'style="width: 200px"',
                  title       : w2utils.lang('Notification'),
                  ok_text     : w2utils.lang('Ok'),
                  cancel_text : w2utils.lang('Cancel'),
                  width       : 400,
                  height      : 200
              })
              .change(function (event) {
                  //console.log('change', event);
              })
              .ok(function (event) {
                  //alert( event );
                  addSubscriptionQueue(event);
              });


          },
          //onEdit: function (event) {
          //    w2alert('edit');
          //},
          onDelete: function (event) {
              //console.log('delete has default behavior');
              event.preventDefault();
              var record = w2ui['sublist'].get(selectedId);
              //w2alert(record.subname);
              //alert(event);
              w2confirm('Delete '+record.subname+'?', function btn(answer) {
                  //console.log(answer); // Yes or No -- case-sensitive
                  if(answer == 'Yes'){
                    deleteSubscriptionQueue(record.subname);
                  }
              });

          },
          onSave: function (event) {
              w2alert('save');
          },
          onSelect: function(event) {

              selectedId = event.recid;
              var record = w2ui['sublist'].get(selectedId);
              loadSubscriptionDetail(record.subname);
              w2ui['filebuttons'].enable('push');
          },
          onContextMenu: function(event) {
              //w2alert(event);
              addSubscriptionQueue(event);
              loadSubscriptionLists();
          }
      });
      //w2ui['adminLayout'].content('right', "");
      $('#versions_grid').html('');
      $('#info_form').html('');
      $('#v_buttons').html('');

      w2ui['adminLayout'].content('main', w2ui['sublist']);

      loadSubscriptionLists();
      onSubscriptionLoad();
}


function onSubscriptionLoad()
{

  $(function () {
      var fbut = w2ui["filebuttons"];
      if(fbut != null ) fbut.destroy();
      w2ui.adminLayout.refresh('bottom');
      $('#filetools').w2toolbar({
          name: 'filebuttons',
          items: [
              { type: 'button', id: 'push', checked: false, text: 'Push Notification', icon: 'fa fa-star' },
              { type: 'break' }
          ],
          onClick: function (event) {
              //console.log('Target: '+ event.target, event);
              if(event.target == 'push')
              {
                  selectMessageFile();
              }
          }
      });
      w2ui['filebuttons'].disable('push');
  });
}

function selectMessageFile()
{
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
                //"       sendMessageTopic(file);"+
                //"       $('#preview').html('<img style=\"height: 250px; width: 400px;\" src=\"'+file+'\"/>');"+
                "     }"+
                "     var fileSel = selectFile;"+
                "     function clickOk(){"+
                //"       alert(selectedFile);"+
                "       sendMessageTopic(selectedFile);"+
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
                "           processRFSClick(event, 'xml', fileSel);"+
                "       }"+
                "       });"+
                "   setSideBar(w2ui.popsidebar);"+
                "   w2ui['popsidebar'].click('pages');"+
                "</script></div><div id='preview' style='float: right; height: 250px; width: 300px;'></div></div>",
      buttons : '<button class="w2ui-btn" onclick="clickOk(); w2popup.close();">Ok</button>'+
                '<button class="w2ui-btn" onclick="w2popup.close()">Cancel</button>'
  });

}


function sendMessageTopic(loadFile)
{
  loadFile = loadFile.substring(0, loadFile.lastIndexOf("."))+".fcm";
  //alert(loadFile);
  var record = w2ui['sublist'].get(selectedId);
  //$(function () {
    $.get( "/android/android_device", {"action": "push_notification", "topic": record.subname, "file": loadFile} )
      .done(function( data ) {
        w2alert(data.success);
      })
      .fail(function() {
          w2alert("Could not send notification");
      });
    //});
}

function loadSubscriptionDetail(sub_name)
{
  var relement = w2ui["relement"];
  if(relement != null ) relement.destroy();
  w2ui.adminLayout.refresh('right');
  //w2alert(w2ui.adminLayout.content('right'));
  $("#versions_grid").w2grid({
      name: 'relement',
      show: {
          //toolbar: true,
          footer: true,
          //toolbarAdd: true,
          //toolbarDelete: true,
          //toolbarSave: true,
          lineNumbers    : true,
          //toolbarEdit: false
      },
      searches: [
          { field: 'user', caption: 'User Name', type: 'text' }
      ],
      columns: [
          //{ field: 'recid', caption: 'ID', size: '50px', sortable: true, attr: 'align=center' },
          { field: 'user', caption: 'User', size: '20%', sortable: true },
          { field: 'device', caption: 'Device ID', size: '80%', sortable: false }
      ],
      onAdd: function (event) {
          //w2alert('add');
      },
      //onEdit: function (event) {
      //    w2alert('edit');
      //},
      onDelete: function (event) {
      //    event.preventDefault();
      //    var record = w2ui['sublist'].get(selectedId);
      //    w2confirm('Delete '+record.subname+'?', function btn(answer) {
      //        if(answer == 'Yes'){ // Yes or No -- case-sensitive
      //          deleteSubscriptionQueue(record.subname);
      //        }
      //    });

      },
      onSave: function (event) {
          w2alert('save');
      },
      onSelect: function(event) {
          //w2alert(event.recid);
          selectedId = event.recid;
      },
  });
  //w2ui['adminLayout'].content('right', w2ui['relement']);
  w2ui['relement'].clear();
  //w2alert(JSON.stringify(subscriptionData));
  var nextObj = subscriptionData["subscriptions"][sub_name];
  Object.keys(nextObj).forEach(function(key) {
      var value = nextObj[key];
      //alert(key+"\n\n"+value);
      var uname = value.substring(0, value.indexOf("|"));
      var dname = value.substring(value.indexOf("|")+1, value.length);
      var nrecid = w2ui['relement'].total + 1;
      w2ui['relement'].add({ recid: nrecid, user: uname, device: dname });
  });
}


function loadSubscriptionLists()
{
  $.get( "/android/android_device", {"action": "subscriptions"} )
    .done(function( data ) {
      subscriptionData = data;
      //alert(data);
      //alert(JSON.stringify(data));
      w2ui['sublist'].clear();
      var nextObj = data["subscriptions"];
      Object.keys(nextObj).forEach(function(key) {
          var value = nextObj[key];
          //alert(key);
          var nrecid = w2ui['sublist'].total + 1;
          w2ui['sublist'].add({ recid: nrecid, subname: key, subcount: value.length });
      });
    });


}

function addSubscriptionQueue(list_name)
{

  $.get( "/android/android_device", {"action": "add_subscription", "ssname": list_name} )
    .done(function( data ) {
      //w2alert(JSON.stringify(data));
      w2ui['sublist'].clear();
      loadSubscriptionLists();
    });

}

function deleteSubscriptionQueue(list_name)
{
  $.get( "/android/android_device", {"action": "del_subscription", "ssname": list_name} )
    .done(function( data ) {
      //w2alert(JSON.stringify(data));
      w2ui['sublist'].clear();
      loadSubscriptionLists();
    });

}
