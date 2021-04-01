
control VlanIngressProc(inout headers hdr,
                inout metadata meta,
                in psa_ingress_input_metadata_t in_meta){
action add_vlan(){
    hdr.vlan.setValid();
    hdr.vlan.etherType = hdr.ethernet.etherType;
    hdr.ethernet.etherType = TYPE_VLAN;
    
}
action nop() {
    
}
table VlanIngressProc_t {
    key = {
        in_meta.ingress_port : exact;
      //  hdr.vlan                        : valid;
        hdr.vlan.vid                    : exact;
        }
    actions = {
        add_vlan;
        nop;
    }
    size = 64;
}
apply {
            VlanIngressProc_t.apply();
        }
}



