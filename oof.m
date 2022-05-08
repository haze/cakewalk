#import <Foundation/Foundation.h>

int main(int argc, const char *argv[]) {
  NSLog(@"Hello, World: '%s'", [NSString respondsToSelector:@selector(string)]?"yes":"no");
  return 0;
}
