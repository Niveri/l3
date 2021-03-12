
struct MacLearnDigest{
    bit<48> srcAddr;
    bit<9>  ingress_port;
    bit<12> vlan_id;
}

control mac_learning(
                inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){
        action mac_learn(){
            digest<MacLearnDigest>((bit<32>)1024, {hdr.ethernet.srcAddr, standard_metadata.ingress_port});
        }
        table mac_learning {
                key  = {
                    hdr.ethernet.srcAddr : exact;
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