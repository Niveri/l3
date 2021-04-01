



control Switching (inout headers hdr,
            inout metadata meta,
           inout psa_ingress_output_metadata_t out_meta){
                
            action forward(PortId_t port){
                out_meta.egress_port = port;
            }
            action broadcast() {
                out_meta.multicast_group = (MulticastGroup_t) 1;
            }
            table switching {
                key  = {
                    hdr.ethernet.dstAddr : exact;
                    hdr.vlan.vid             : exact;
                }
                actions = {
                    forward;
                    broadcast;
                }
                size = 4000;

            }
            apply{
                    switching.apply();
                }
 }
            