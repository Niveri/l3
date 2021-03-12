#include "actions.p4"
#include "headers.p4"
#include "metadata.p4"
#include "parser.p4"
#include "switching.p4"
#include "mac_learning.p4"
#include "acl.p4"
#include "routing.p4"
#include "routable.p4"
#include "vlan_egress_process.p4"
#include "vlan_ingress_process.p4"

#include <core.p4>
#include <v1model.p4>



control MyIngress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
   
    VlanIngressProc() vlanIngressProc;
    mac_learning() mac_learning;
    Routable() routable;
    Switching() switching;
    Acl() acl;
    Routing() routing;
    apply {
        vlanIngressProc.apply(hdr, meta, standard_metadat);
        mac_learning.apply(hdr, meta, standard_metadat);
        routable.apply(hdr, meta, standard_metadat);
        routing.apply(hdr, meta, standard_metadat);
        switching.apply(hdr, meta, standard_metadat);
    }
}
control MyEgress(inout headers hdr,
                inout metadata meta, 
                inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control MyComputeChecksum(inout headers hdr,
                        inout metadata meta)
{
    apply {
        update_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.id,
                hdr.ipv4.flags,
                hdr.ipv4.fragsOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );
    }
}
control MyVerifyChecksum(inout headers hdr,
                        inout metadata meta)
{
    apply {
        verify_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.id,
                hdr.ipv4.flags,
                hdr.ipv4.fragsOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;