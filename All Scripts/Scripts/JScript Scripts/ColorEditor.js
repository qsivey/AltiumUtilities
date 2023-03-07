function ColorEdit () {

     var Board;
     var i = 0;
     Board = PCBServer.GetCurrentPCBBoard;

     while (i < 100) {
           if (IPCB_Component.FootprintConfiguratorName() == 'AXIAL10R') {
           IPCB_ComponentBody.BodyColor3D() = 0;
           }
     }
}




