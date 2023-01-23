use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_init_logger(port_: i64) {
    wire_init_logger_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_init_light_client(port_: i64) {
    wire_init_light_client_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_json_rpc_send(port_: i64, chain_id: usize, req: *mut wire_uint_8_list) {
    wire_json_rpc_send_impl(port_, chain_id, req)
}

#[no_mangle]
pub extern "C" fn wire_set_json_rpc_response_sink(port_: i64) {
    wire_set_json_rpc_response_sink_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_add(port_: i64, left: usize, right: usize) {
    wire_add_impl(port_, left, right)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
