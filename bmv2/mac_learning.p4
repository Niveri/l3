
#include "actions.p4"

struct MacLearnDigest{
    bit<48> srcAddr;
    bit<9>  ingress_port;
    bit<12> vlan_id;
}

control Mac_learning(
                inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){
        action nop() {
    
        }
        
        action mac_learn(){
            digest<MacLearnDigest>((bit<32>)1024, {hdr.ethernet.mac_srcAddr, standard_metadata.ingress_port, hdr.vlan.vid});
        }
        table mac_learning {
                key  = {
                    hdr.ethernet.mac_srcAddr : exact;
                }
                actions = {
                    mac_learn;
                    nop;
                }
                size = 4000;

            }
        apply{
                    mac_learning.apply();
                }

                
}