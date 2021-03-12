struct int_metadata {
    bit <4> mcast_grp;
    bit <4> egress_if;
    bit <16> mcast_hash;
    bit <32> lf_field_list;
}

struct metadata {
    bit <16> srcPort;
    bit <16> dstPort;
}