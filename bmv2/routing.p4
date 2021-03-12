



control Routing (inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){

        action set_nhop(macAddr_t srcAddr, macAddr_t dstAddr,vlan_id vid){
                hdr.ethernet.mac_srcAddr = srcAddr;
                hdr.ethernet.mac_dstAddr = dstAddr;
                hdr.vlan.vid = vid;
                hdr.ipv4.ttl = hdr.ipv4.ttl -1;

        }
        action drop() {
            mark_to_drop(standard_metadata);
        }
        table routing {
            key = {
                hdr.ipv4.dstAddr: lpm;
            }
            actions = {
                set_nhop;
                drop;
            }
            size = 2000;
        }
        apply {
            routing.apply();
        }
}
