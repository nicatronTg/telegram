//
//  TLChatCategory.m
//  Messenger for Telegram
//
//  Created by Dmitry Kondratyev on 2/26/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "TLChatCategory.h"

@implementation TLChat (Category)

DYNAMIC_PROPERTY(DType);

- (TLChatType) type {
    NSNumber *type = [self getDType];
    if(!type)
        type = [NSNumber numberWithInt:[self rebuildType]];
    return [type intValue];
}

DYNAMIC_PROPERTY(DDialog);

-(TL_conversation *)dialog {
    TL_conversation *dialog = [self getDDialog];
    
    if(!dialog) {
        if([self isKindOfClass:[TL_channel class]])
            dialog = [[ChannelsManager sharedManager] find:-self.n_id];
        else
            dialog = [[DialogsManager sharedManager] findByChatId:self.n_id];
        [self setDDialog:dialog];
    }
    
    if(!dialog) {
        dialog = [[Storage manager] selectConversation:self.peer];
        
        if(!dialog) {
            if([self isKindOfClass:[TL_channel class]])
                dialog = [[DialogsManager sharedManager] createDialogForChannel:self];
            else
                dialog = [[DialogsManager sharedManager] createDialogForChat:self];
        }
        
        else
            [[DialogsManager sharedManager] add:@[dialog]];
        
        [self setDDialog:dialog];
    }
    
    return dialog;

}

-(TLChatFull *)chatFull  {
    return [[FullChatManager sharedManager] find:self.n_id];
}

- (void) setType:(TLChatType)type {
    [self setDType:[NSNumber numberWithInt:type]];
}


- (TLChatType)rebuildType {
    int type;
    
    if([self isKindOfClass:[TL_chatForbidden class]])
        type = TLChatTypeForbidden;
    else if([self isKindOfClass:[TL_chatEmpty class]])
        type = TLChatTypeEmpty;
    else
        type = TLChatTypeNormal;
   
    
    [self setType:type];
    return type;
}

DYNAMIC_PROPERTY(DIALOGTITLE);

- (NSAttributedString *) dialogTitle {
    NSMutableAttributedString *dialogTitleAttributedString = [[NSMutableAttributedString alloc] init];
    
    if([self isKindOfClass:[TL_channel class]]) {
        [dialogTitleAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:chatIconAttachment()]];
        [dialogTitleAttributedString setSelectionAttachment:chatIconSelectedAttachment() forAttachment:chatIconAttachment()];
    }
    
    
    [dialogTitleAttributedString appendString:self.cropTitle withColor:NSColorFromRGB(0x333333)];
    [dialogTitleAttributedString setSelectionColor:NSColorFromRGB(0xffffff) forColor:NSColorFromRGB(0x333333)];
    [dialogTitleAttributedString setFont:[NSFont fontWithName:@"HelveticaNeue" size:14] forRange:dialogTitleAttributedString.range];
    
    
    
    
    [self setDIALOGTITLE:dialogTitleAttributedString];
    
    return [self getDIALOGTITLE];

    
    [self setDIALOGTITLE:dialogTitleAttributedString];
    
    return [self getDIALOGTITLE];
}

DYNAMIC_PROPERTY(TITLEFORMESSAGE);

- (NSAttributedString *) titleForMessage {
    NSMutableAttributedString *dialogTitleAttributedString = [[NSMutableAttributedString alloc] init];
    
    [dialogTitleAttributedString appendString:self.cropTitle withColor:NSColorFromRGB(0x222222)];
    [dialogTitleAttributedString setFont:[NSFont fontWithName:@"HelveticaNeue" size:14] forRange:dialogTitleAttributedString.range];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    [dialogTitleAttributedString addAttribute:NSParagraphStyleAttributeName value:style range:dialogTitleAttributedString.range];
    
    [self setTITLEFORMESSAGE:dialogTitleAttributedString];
    
    return [self getTITLEFORMESSAGE];
}

-(NSString *)cropTitle {
    return self.title.length > 50 ? [self.title substringToIndex:50] : self.title;
}

- (NSAttributedString *)titleForChatInfo {
    return [[NSAttributedString alloc] initWithString:self.cropTitle];
}

- (NSAttributedString *)statusAttributedString {
    return [[NSMutableAttributedString alloc] initWithString:@"string"];
}

static NSTextAttachment *chatIconAttachment() {
    static NSTextAttachment *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NSMutableAttributedString textAttachmentByImage:[image_chat() imageWithInsets:NSEdgeInsetsMake(0, 1, 0, 4)]];
    });
    return instance;
}

static NSTextAttachment *chatIconSelectedAttachment() {
    static NSTextAttachment *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NSMutableAttributedString textAttachmentByImage:[image_chatHighlighted() imageWithInsets:NSEdgeInsetsMake(0, 1, 0, 4)]];
    });
    return instance;
}


- (NSAttributedString *)statusForSearchTableView {
    NSMutableAttributedString *str;
    if(!str) {
        str = [[NSMutableAttributedString alloc] init];
        
        [str appendString:[NSString stringWithFormat:@"%d %@", self.participants_count, self.participants_count > 1 ?  NSLocalizedString(@"Conversation.Members", nil) : NSLocalizedString(@"Conversation.Member", nil)] withColor:NSColorFromRGB(0x9b9b9b)];

        
        int online = [[FullChatManager sharedManager] getOnlineCount:self.n_id];
        if(online > 0) {
            [str appendString:@", " withColor:NSColorFromRGB(0x9b9b9b)];
            [str appendString:[NSString stringWithFormat:@"%d %@", online, NSLocalizedString(@"Account.Online", @"")] withColor:NSColorFromRGB(0x9b9b9b)];
        }
        
        [str setSelectionColor:NSColorFromRGB(0xffffff) forColor:BLUE_UI_COLOR];
        [str setSelectionColor:NSColorFromRGB(0xfffffe) forColor:NSColorFromRGB(0x9b9b9b)];
        [str setFont:[NSFont fontWithName:@"HelveticaNeue" size:13] forRange:str.range];
    }
    return str;
}

- (NSAttributedString *)statusForMessagesHeaderView {
    
    

    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    if([self isKindOfClass:[TL_channel class]])
    {
        [attributedString appendString:NSLocalizedString(@"Conversation.ChannelTitle", nil) withColor:NSColorFromRGB(0xa9a9a9)];
        
        return attributedString;
    }
    
    [attributedString appendString:[NSString stringWithFormat:@"%d %@", self.participants_count, self.participants_count > 1 ?  NSLocalizedString(@"Conversation.Members", nil) : NSLocalizedString(@"Conversation.Member", nil)] withColor:NSColorFromRGB(0xa9a9a9)];
    
    int online = [[FullChatManager sharedManager] getOnlineCount:self.n_id];
    if(online > 0) {
        [attributedString appendString:@", " withColor:NSColorFromRGB(0xa9a9a9)];
        [attributedString appendString:[NSString stringWithFormat:@"%d %@", online, NSLocalizedString(@"Account.Online", @"")] withColor:NSColorFromRGB(0x9b9b9b)];
    }
    
    
    [attributedString setFont:[NSFont fontWithName:@"HelveticaNeue" size:12] forRange:attributedString.range];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:2];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];

    
    return attributedString;
}

-(id)inputPeer {
    return [self isKindOfClass:[TL_channel class]] ? [TL_inputChannel createWithChannel_id:self.n_id access_hash:self.access_hash] : ([self isKindOfClass:[TL_peerSecret class]] ? [TL_inputEncryptedChat createWithChat_id:self.n_id access_hash:self.access_hash] : nil);
}



-(TLPeer *)peer {
    return [self isKindOfClass:[TL_channel class]] ? [TL_peerChannel createWithChannel_id:self.n_id] : [TL_peerChat createWithChat_id:self.n_id];
}


-(BOOL)isAdmin {
    return self.flags & (1 << 0);
}
-(BOOL)isBroadcast {
    return self.flags & (1 << 5);
}
-(BOOL)isPublic {
    return self.flags & (1 << 6);
}

-(BOOL)left {
    return self.flags & (1 << 2);
}

-(BOOL)isKicked {
    return self.flags & (1 << 1);
}

-(BOOL)isPublisher {
    return self.flags & (1 << 3);
}

-(BOOL)isModerator {
    return self.flags & (1 << 4);
}

-(NSString *)usernameLink {
    return self.username.length > 0 ? [NSString stringWithFormat:@"https://telegram.me/%@",self.username] : @"";
}



@end
