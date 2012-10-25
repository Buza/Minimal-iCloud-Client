//
//  MyDocument.m
//  DataGenerator
//
//  Created by buza on 10/22/12.
//  Copyright (c) 2012 buzamoto. All rights reserved.
//

#import "MyDocument.h"

#define TITLE_FILENAME      @"doc.title"
#define DESC_FILENAME       @"doc.description"

@interface MyDocument()
@property (nonatomic, strong) NSFileWrapper *fileWrapper;
@end

@implementation MyDocument

@synthesize fileWrapper;
@synthesize title = _title;
@synthesize description = _description;

- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary *)wrappers preferredFilename:(NSString *)preferredFilename
{
    @autoreleasepool
    {
        NSMutableData * data = [NSMutableData data];
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSMutableDictionary * wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.title toWrappers:wrappers preferredFilename:TITLE_FILENAME];
    [self encodeObject:self.description toWrappers:wrappers preferredFilename:DESC_FILENAME];
    
    NSFileWrapper *fw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    
    return fw;
}

- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString *)preferredFilename
{
    NSFileWrapper * fw = [self.fileWrapper.fileWrappers objectForKey:preferredFilename];
    if (!fw)
    {
        DLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData * data = [fw regularFileContents];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
}

- (NSString *)title
{
    if (_title == nil) {
        if (self.fileWrapper != nil)
        {
            self.title = [self decodeObjectFromWrapperWithPreferredFilename:TITLE_FILENAME];
        } else {
            self.title = @"";
        }
    }
    return _title;
}

- (NSString *)description
{
    if (_description == nil) {
        if (self.fileWrapper != nil)
        {
            self.description = [self decodeObjectFromWrapperWithPreferredFilename:DESC_FILENAME];
        } else {
            self.description = @"";
        }
    }
    return _description;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.fileWrapper = (NSFileWrapper *) contents;
    
    self.title = nil;
    self.description = nil;
    
    return YES;
}

@end
