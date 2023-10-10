
function CreateTree($tree, data, selectedIDs, idKey, titleKey, hideCheckBox, onSelectFunction) {
    // to intialize tree
    if (!selectedIDs) selectedIDs = [];
        var ParentNode = {};
        ParentNode.key = "*";
        ParentNode.title = CommonResources.SelectAll;
        ParentNode.isFolder = true;
        ParentNode.expand = true;
        ParentNode.children = GetTreeDataFormat(data, idKey, titleKey, "", selectedIDs);
        var TreeData = [ParentNode];
    $tree.dynatree({
        fx: { height: "toggle", duration: 300 },
        checkbox: !hideCheckBox,
        selectMode: 3,
        onDblClick: function (node, event) {
            if (node.getEventTargetType(event) == "title") node.toggleSelect();
        },
        onKeydown: function (node, event) {
            if (event.which == 32) { node.toggleSelect(); return false; }
        },
        children: TreeData,
        onSelect: onSelectFunction
    });

    $('span.dynatree-node a')
   .live('mouseover', function () {
       $(this).addClass('ui-state-hover');
   })
   .live('mouseout', function () {
       $(this).removeClass('ui-state-hover');
   });
}
function GetSelectedValues($tree) {
    var __tree = $tree.dynatree("getTree");
    var SelectedNodes = __tree.getSelectedNodes(false);
    var selectedIds = [];
    $.each(SelectedNodes, function (i, node) {
        if (node.hasChildren() === false) {
            selectedIds.push(node.data.key);
        }
    });
    return selectedIds;
}