
control VlanEgressProc(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

        action strip_vlan(){
            hdr.ethernet.etherType = hdr.vlan.etherType;
            hdr.vlan.setInvalid();
    
        }
        table VlanEgressProc_t {
            key = {
                standard_metadata.egress_spec : exact;
        
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

