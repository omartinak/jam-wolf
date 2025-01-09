package game

//import "base:runtime"
import "core:sync"
import "core:prof/spall"

spall_ctx: spall.Context
@(thread_local) buffer_backing: []u8
@(thread_local) spall_buffer: spall.Buffer

//@(instrumentation_enter)
//spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
//    spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
//}
//
//@(instrumentation_exit)
//spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
//    spall._buffer_end(&spall_ctx, &spall_buffer)
//}

create_profiler :: proc() {
    spall_ctx = spall.context_create("jam-wolf_trace.spall")
    buffer_backing = make([]u8, spall.BUFFER_DEFAULT_SIZE)
    spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
}

destroy_profiler :: proc() {
    spall.buffer_destroy(&spall_ctx, &spall_buffer)
    delete(buffer_backing)
    spall.context_destroy(&spall_ctx)
}
