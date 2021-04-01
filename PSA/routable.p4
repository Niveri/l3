
control Routable (inout headers hdr,
                inout metadata meta,
                inout psa_ingress_output_metadata_t out_meta){

       
        action route() {
           // routing.apply(hdr, meta, standard_metadata);
        }
        action nop() {
    
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