
control VlanIngressProc(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

        action add_vlan(){
            hdr.vlan.setValid();
            hdr.vlan.etherType = hdr.ethernet.ethernet_h;
            hdr.ethernet.etherType = TYPE_VLAN;
    
        }
        table VlanIngressProc_t {
            key = {
                standard_metadata.inggress_port : exact;
                hdr.vlan                        : valid;
                hdr.vlan.vid                    : exact;
            }
            actions = {
                add_vlan;
                nop;
            }
            size = 64;
        }
        apply {
            routing.apply();
        }


}

