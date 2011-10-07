// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** This function installs an interrupt handler on the given XUD IN endpoint.
 * This may either be a bulk IN endpoint or an interrupt-endpoint.
 * Both the channel and the XUD endpoint are to be provided.
 *
 * \param c     channel on which the XUD is providing data for this endpoint
 *
 * \param x     XUD endpoint associated with the above channel
 */
extern void XUD_interrupt_IN(chanend c, XUD_ep x);

/** This function installs an interrupt handler on the given XUD OUT endpoint.
 * This must be a bulk out endpoint.
 * Both the channel and the XUD endpoint are to be provided.
 *
 * \param c     channel on which the XUD is providing data for this endpoint
 *
 * \param x     XUD endpoint associated with the above channel
 */
extern void XUD_interrupt_OUT(chanend c, XUD_ep x);

/** This function enables the interrupts and installs the synchronisation
 * channel. Every handled packet will result in a single token being send
 * over the channel. The channel must be declared as a chan and not be
 * passed to any other thread (it will point to itself!). The token sent is
 * the last byte of the XUD_ep variable of the endpoint that got handled.
 *
 * If it is an IN endpoint, then it means that data has been taken away by
 * the host, and new data is to be provided using the XUD_provide_IN_buffer
 * call.
 *
 * If it is an OUT endpoint then the datalength is to be computed by
 * calling XUD_compute_OUT_length, and a new buffer is to be provided using
 * XUD_provide_OUT_buffer.
 *
 * In either case, the endpoint will be NAKed until a new buffer is
 * provided.
 *
 * \param serv channel over which the interrupt handlers will send the end point IDs.
 */
extern void XUD_interrupt_enable(chanend serv);

/** This function makes a buffer with data available to an IN endpoint. The
 * buffer is located at the given address/length, and a PID is provided
 * (unless it is 0 in which case it is created as required by the USB
 * spec).
 *
 * \param  e      Endpoint to which to supply a buffer with data
 * \param  pid    PID to use for the next IN request - or zero if toggling PID0/PID1
 * \param  buffer Address of the buffer
 * \param  len    Number of bytes in the buffer, must be less than wMaxPacketSize on
 *                this endpoint
 */
extern void XUD_provide_IN_buffer(XUD_ep e, int pid, unsigned buffer[], unsigned len);

/** This function makes a buffer with data available to an IN endpoint. The
 * buffer is located at the given address/length, and a PID is provided
 * (unless it is 0 in which case it is created as required by the USB
 * spec).
 *
 * \param  e      Endpoint to which to supply a buffer with data
 * \param  pid    PID to use for the next IN request - or zero if toggling PID0/PID1
 * \param  buffer Address of the buffer
 * \param  index  index of first BYTE in buffer.
 * \param  len    Number of bytes in the buffer, must be less than wMaxPacketSize on
 *                this endpoint
 */
extern void XUD_provide_IN_buffer_i(XUD_ep e, int pid, unsigned buffer[], int index, unsigned len);

/** This function makes a buffer available to an OUT endpoint. The buffer
 * must be large enough to hold a maxPacketSize on that endpoint plus 6
 * bytes (!).
 *
 * \param  e      Endpoint on which to supply a buffer.
 * \param  buffer Buffer in which to receive contents of next OUT on this endpoint
 */ 
extern void XUD_provide_OUT_buffer(XUD_ep e, unsigned buffer[]);

/** This function makes a buffer available to an OUT endpoint. The buffer
 * must be large enough to hold a maxPacketSize on that endpoint plus 6
 * bytes (!). An index is provided to state where in the buffer to start.
 *
 * \param  e      Endpoint on which to supply a buffer.
 * \param  buffer Buffer in which to receive contents of next OUT on this endpoint
 * \param  index  index of first BYTE in buffer.
 */ 
extern void XUD_provide_OUT_buffer_i(XUD_ep e, unsigned buffer[], int index);

/** This function computes the number of bytes received in the given buffer
 * on the given endpoint. It should be called before a new buffer is
 * installed.
 *
 * \param  e      Endpoint on which to compute the length of the received buffer
 * \param  buffer Buffer on which to compute the length
 * 
 * \return        The length of the block of data just received.
 */ 
extern int XUD_compute_OUT_length(XUD_ep e, unsigned buffer[]);
