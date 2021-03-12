control Routable (inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){
        action route() {
            ///routing?
        }
        action nop() {
    
        }

        
        table routable {
            key = {
                hdr.ethernet.mac_srcAddr: exact;   //delete?
                hdr.ethernet.mac_dstAddr: exact;   //lpm
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