//Access list


control Acl (inout headers hdr,
            inout metadata meta,
            inout psa_ingress_output_metadata_t out_meta){

            action nop() {
    
            }
           
            action drop_acl(){
               ingress_drop(out_meta);
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


            
