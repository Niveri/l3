control Routable (inout headers hdr,
                inout metadata meta){
        action route() {

        }

        
        table routable {
            key = {
                hdr.ethernet.srcAddr: exact;   //delete?
                hdr.ethernet.dstAddr: exact;   //lpm
                hdr.vlan.vid        : exact;
            }
            actions = {
                route;
                nop;
            }
            size = 64;
        }
        apply {
            routable.apply();
        }
}