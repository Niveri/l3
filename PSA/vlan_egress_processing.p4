control VlanEgressProc(inout headers hdr,
                inout metadata meta,
                in psa_egress_input_metadata_t out_meta) {

        action strip_vlan(){
            hdr.ethernet.etherType = hdr.vlan.etherType;
            hdr.vlan.setInvalid();
    
        }
        action nop() {
    
        }
        table VlanEgressProc_t {
            key = {
                out_meta.egress_port  : exact;
        
            }
            actions = {
                strip_vlan;
                nop;
            }
            size = 64;
        }
        apply {
            VlanEgressProc_t.apply();
        }


}
