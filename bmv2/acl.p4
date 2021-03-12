//Access lists
#include <core.p4>
#include <v1model.p4>



control Acl (inout headers hdr,
            inout metadata meta,
            inout standard_metadata_t standard_metadata){

            action nop() {
    
            }
           
            action drop_acl(){
                mark_to_drop(standard_metadata);
            }
                table acl {
                    key = {
                        hdr.ipv4.srcAddr: ternary;
                        hdr.ipv4.dstAddr: ternary;
                        hdr.ipv4.protocol: ternary;
                        meta.srcPort: ternary;
                        meta.dstPort: ternary;
                    }
                actions = {
                    nop;
                    drop_acl;
                }
                size = 1000;
                }
                apply{
                    acl.apply();
                }
}


            
