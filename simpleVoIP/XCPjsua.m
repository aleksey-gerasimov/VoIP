/*
 * Copyright (C) 2014 Xianwen Chen <xianwen@xianwenchen.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "XCPjsua.h"

#import <pjsua-lib/pjsua.h>

#define THIS_FILE "XCPjsua.c"

const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info);
static void error_exit(const char *title, pj_status_t status);

@interface XCPjsua ()
@end

@implementation XCPjsua
{
    pjsua_acc_id _acc_id;
    RegisterCallBack _registerCallBack;
}

+ (XCPjsua *)sharedXCPjsua
{
    static XCPjsua *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XCPjsua alloc] init];
    });
    return sharedInstance;
}

- (int)startPjsipAndRegisterOnServer:(char *)sipDomain
                        withUserName:(char *)sipUser
                         andPassword:(char *)password
                            callback:(RegisterCallBack)callback
{
    pj_status_t status;
    
    // Create pjsua first
    status = pjsua_create();
    if (status != PJ_SUCCESS) error_exit("Error in pjsua_create()", status);
    
    // Init pjsua
    {
        // Init the config structure
        pjsua_config cfg;
        pjsua_config_default (&cfg);
        
        cfg.cb.on_incoming_call = &on_incoming_call;
        cfg.cb.on_call_media_state = &on_call_media_state;
        cfg.cb.on_call_state = &on_call_state;
        cfg.cb.on_reg_state2 = &on_reg_state2;
        
        // Init the logging config structure
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
        
        // Init the pjsua
        status = pjsua_init(&cfg, &log_cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error in pjsua_init()", status);
    }
    
    // Add UDP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5080;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    
    // Add TCP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5080;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    
    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        // Account ID
        char sipId[MAX_SIP_ID_LENGTH];
        sprintf(sipId, "sip:%s@%s", sipUser, sipDomain);
        cfg.id = pj_str(sipId);
        
        // Reg URI
        char regUri[MAX_SIP_REG_URI_LENGTH];
        sprintf(regUri, "sip:%s", sipDomain);
        cfg.reg_uri = pj_str(regUri);
        
        // Account cred info
        cfg.cred_count = 1;
        cfg.cred_info[0].scheme = pj_str("digest");
        cfg.cred_info[0].realm = pj_str(sipDomain);
        cfg.cred_info[0].username = pj_str(sipUser);
        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        cfg.cred_info[0].data = pj_str(password);
        
        status = pjsua_acc_add(&cfg, PJ_TRUE, &_acc_id);
        if (status != PJ_SUCCESS) error_exit("Error adding account", status);
    }
    
    _registerCallBack = callback;
    
    return 0;
}

- (void)makeCallTo:(char*)destUri
{
    pj_status_t status;
    pj_str_t uri = pj_str(destUri);
    
    status = pjsua_call_make_call(_acc_id, &uri, 0, NULL, NULL, NULL);
    if (status != PJ_SUCCESS) error_exit("Error making call", status);
}

- (void)endCall
{
    pjsua_call_hangup_all();
}

- (void)handleRegistrationStateChangeWithRegInfo: (pjsua_reg_info *)info
{
    switch (info->cbparam->code) {
        case 200:
            // register success
            _registerCallBack(YES);
            break;
        case 401:
            // illegal credential
            _registerCallBack(NO);
            break;
        default:
            break;
    }
}

@end

/* Callback called by the library when registration state has changed */
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info)
{
    [[XCPjsua sharedXCPjsua] handleRegistrationStateChangeWithRegInfo: info];
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    
    pjsua_call_get_info(call_id, &ci);
    
    PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,
              ci.remote_info.ptr));
    
    /* Automatically answer incoming calls with 200/OK */
    pjsua_call_answer(call_id, 200, NULL, NULL);
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(e);
    
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,(THIS_FILE, "Call %d state=%.*s", call_id,
              (int)ci.state_text.slen,
              ci.state_text.ptr));
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

/* Display error and exit application */
static void error_exit(const char *title, pj_status_t status)
{
    pjsua_perror(THIS_FILE, title, status);
    pjsua_destroy();
    exit(1);
}
