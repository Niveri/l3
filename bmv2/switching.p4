#include <core.p4>
#include <v1model.p4>

#include "headers.p4"



control Switching (inout headers hdr,
            inout metadata meta,
            inout standard_metadata_t standard_metadata){
                
            action forward(egressSpec_t port){
                standard_metadata.egress_spec = port;
            }
            action broadcast() {
                standard_metadata.mcast_grp = 1;
            }
            table switching {
                key  = {
                    hdr.ethernet.dstAddr : exact;
                    vlan.vid             : exact;
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
            