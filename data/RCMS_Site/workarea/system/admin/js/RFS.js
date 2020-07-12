var mySideBar = null;
function setSideBar(mysidebar)
{
  mySideBar = mysidebar;
}
/*
``  Load a subsection of the Remote File System (RFS)
*/
function loadRFS(parentId, idPrefix, path)
{
    //alert("ParentId : "+parentId);
    $.get( path, {} )
      .done(function( data ) {
        //alert("Processing: "+data);
        processRFS(parentId, idPrefix, data);
      });
}
/*
``  Process a subsection of the Remote File System (RFS)
*/
function processRFS(parentId, idPrefix, obj)
{
  var nextObj = obj["files"];
  Object.keys(nextObj).forEach(function(key) {
      var value = nextObj[key];
      addFileNode(parentId, idPrefix+key, value);
  });
}
/*
``  Add a File/Folder node to the local representation of the Remote File System (RFS)
*/
function addFileNode(parentId, nodeId, nodeText)
{
  var icon = getIcon(nodeId);
  mySideBar.add(parentId, [{ id: nodeId, text: nodeText, img: icon }]);
  mySideBar.expand(parentId);
}

function processRFSClick(event, fileTypes, callback)
{
    if(event.target == 'pages')
    {
       loadRFS(event.target, 'folder','/admin/actions/list_folders?sub_dir=/&file_type=*');
       loadRFS(event.target, 'file','/admin/actions/list_files?sub_dir=/&file_type={'+fileTypes+'}');
    }
    else if(event.target.startsWith('folder'))
    {
        var folder = event.target;
        var subFolder = folder.substring(6, folder.length);
        loadRFS(event.target, 'folder','/admin/actions/list_folders?sub_dir='+subFolder+'&file_type=*');
        loadRFS(event.target, 'file','/admin/actions/list_files?sub_dir='+subFolder+'&file_type={'+fileTypes+'}');
    }
    else if(event.target.startsWith('file'))
    {
      var file = event.target;
      callback(file.substring(4, file.length));
    }

}


/*
``  Determine what kind of icon to display based on file type
*/
function getIcon(nodeId)
{
  if(nodeId.startsWith("folder"))
    return 'icon-folder-custom';
  else
  {
    var fileType = nodeId.substring(nodeId.indexOf('.'), nodeId.length);
    var icon = "";
    //alert(fileType)
    switch(fileType) {
      case ".admin":
        icon = 'icon-xml';
        break;
      case ".block":
        icon = 'icon-block';
        break;
    }
    return icon;

  }


}
