/*
 * redcloth_attributes.rl
 *
 * Copyright (C) 2008 Jason Garber
 */
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;

import org.jruby.util.ByteList;

public class RedclothAttributes extends RedclothScanService.Base {

%%{

  machine redcloth_attributes;
  include redcloth_common "redcloth_common.java.rl";
  
  C2_CLAS = ( "(" ( [^)#]+ >A %{ STORE("class_buf"); } )? ("#" [^)]+ >A %{STORE("id_buf");} )? ")" ) ;
  C2_LNGE = ( "[" [^\]]+ >A %{ STORE("lang_buf"); } "]" ) ;
  C2_STYL = ( "{" [^}]+ >A %{ STORE("style_buf"); } "}" ) ;
  C2 = ( C2_CLAS | C2_STYL | C2_LNGE )+ ;

  mtext_with_attributes = ( C2 mtext >A %T ) >X ;

  inline := |*

    mtext_with_attributes { SET_ATTRIBUTES(); } ;

  *|;

  link_text_with_attributes = C2 "."* " "* ( mtext+ ) >A %{ STORE("name"); } ;
  link_text_without_attributes = ( mtext+ ) >B %{ STORE_B("name_without_attributes"); } ;

  link_says := |*

    link_text_with_attributes { SET_ATTRIBUTES(); } ;
    link_text_without_attributes { SET_ATTRIBUTE("name_without_attributes", "name"); } ;

  *|;

}%%

%% write data nofinal;

  public void SET_ATTRIBUTES() {
    SET_ATTRIBUTE("class_buf", "class");
    SET_ATTRIBUTE("id_buf", "id");
    SET_ATTRIBUTE("lang_buf", "lang");
    SET_ATTRIBUTE("style_buf", "style");
  }

  public void SET_ATTRIBUTE(String B, String A) {
    buf = ((RubyHash)regs).aref(runtime.newSymbol(B));
    if(!buf.isNil()) {
      ((RubyHash)regs).aset(runtime.newSymbol(A), buf);
    }
  }
 
  private int machine;
  private IRubyObject buf;
   
  public RedclothAttributes(int machine, IRubyObject self, byte[] data, int p, int pe) {
//  System.err.println("RedclothAttributes(data.len: " + data.length + ", p: " + p + ", pe: " + pe + ")");
    this.runtime = self.getRuntime();
    this.self = self;
    this.data = data;
    this.p = p;
    this.pe = p+pe;
    this.eof = p+pe;
    this.regs = RubyHash.newHash(runtime);
    this.buf = runtime.getNil();
    this.machine = machine;
  }

  public IRubyObject parse() {
    %% write init;
  
    cs = machine;

    %% write exec;

    return regs;
  }

  public static IRubyObject attributes(IRubyObject self, IRubyObject str) {
    ByteList bl = str.convertToString().getByteList();
    int cs = redcloth_attributes_en_inline;
    return new RedclothAttributes(cs, self, bl.bytes, bl.begin, bl.realSize).parse();
  }

  public static IRubyObject link_attributes(IRubyObject self, IRubyObject str) {
    ByteList bl = str.convertToString().getByteList();
    int cs = redcloth_attributes_en_link_says;
    return new RedclothAttributes(cs, self, bl.bytes, bl.begin, bl.realSize).parse();
  }
}
