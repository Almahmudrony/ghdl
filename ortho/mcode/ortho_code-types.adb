--  Mcode back-end for ortho - type handling.
--  Copyright (C) 2006 Tristan Gingold
--
--  GHDL is free software; you can redistribute it and/or modify it under
--  the terms of the GNU General Public License as published by the Free
--  Software Foundation; either version 2, or (at your option) any later
--  version.
--
--  GHDL is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or
--  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
--  for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with GCC; see the file COPYING.  If not, write to the Free
--  Software Foundation, 59 Temple Place - Suite 330, Boston, MA
--  02111-1307, USA.
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with GNAT.Table;
with Ortho_Code.Consts; use Ortho_Code.Consts;
with Ortho_Code.Debug;
with Ortho_Code.Abi; use Ortho_Code.Abi;

package body Ortho_Code.Types is
   type Bool_Array is array (Natural range <>) of Boolean;
   pragma Pack (Bool_Array);

   type Tnode_Common is record
      Kind : OT_Kind; -- 4 bits.
      Mode : Mode_Type; -- 4 bits.
      Align : Small_Natural; -- 2 bits.
      Pad0 : Bool_Array (0 .. 21);
      Size : Uns32;
   end record;
   pragma Pack (Tnode_Common);

   type Tnode_Access is record
      Dtype : O_Tnode;
      Pad : Uns32;
   end record;

   type Tnode_Array is record
      Element_Type : O_Tnode;
      Index_Type : O_Tnode;
   end record;

   type Tnode_Subarray is record
      Base_Type : O_Tnode;
      Length : Uns32;
   end record;

   type Tnode_Record is record
      Fields : O_Fnode;
      Nbr_Fields : Uns32;
   end record;

   type Tnode_Enum is record
      Lits : O_Cnode;
      Nbr_Lits : Uns32;
   end record;

   type Tnode_Bool is record
      Lit_False : O_Cnode;
      Lit_True : O_Cnode;
   end record;

   package Tnodes is new GNAT.Table
     (Table_Component_Type => Tnode_Common,
      Table_Index_Type => O_Tnode,
      Table_Low_Bound => O_Tnode_First,
      Table_Initial => 128,
      Table_Increment => 100);

   type Field_Type is record
      Ident : O_Ident;
      Ftype : O_Tnode;
      Offset : Uns32;
      Next : O_Fnode;
   end record;

   package Fnodes is new GNAT.Table
     (Table_Component_Type => Field_Type,
      Table_Index_Type => O_Fnode,
      Table_Low_Bound => 2,
      Table_Initial => 64,
      Table_Increment => 100);

   function Get_Type_Kind (Atype : O_Tnode) return OT_Kind is
   begin
      return Tnodes.Table (Atype).Kind;
   end Get_Type_Kind;

   function Get_Type_Size (Atype : O_Tnode) return Uns32 is
   begin
      return Tnodes.Table (Atype).Size;
   end Get_Type_Size;

   function Get_Type_Align (Atype : O_Tnode) return Small_Natural is
   begin
      return Tnodes.Table (Atype).Align;
   end Get_Type_Align;

   function Get_Type_Align_Byte (Atype : O_Tnode) return Uns32 is
   begin
      return 2 ** Get_Type_Align (Atype);
   end Get_Type_Align_Byte;

   function Get_Type_Mode (Atype : O_Tnode) return Mode_Type is
   begin
      return Tnodes.Table (Atype).Mode;
   end Get_Type_Mode;

   function To_Tnode_Access is new Ada.Unchecked_Conversion
        (Source => Tnode_Common, Target => Tnode_Access);

   function Get_Type_Access_Type (Atype : O_Tnode) return O_Tnode
   is
   begin
      return To_Tnode_Access (Tnodes.Table (Atype + 1)).Dtype;
   end Get_Type_Access_Type;


   function To_Tnode_Array is new Ada.Unchecked_Conversion
     (Source => Tnode_Common, Target => Tnode_Array);

   function Get_Type_Ucarray_Index (Atype : O_Tnode) return O_Tnode is
   begin
      return To_Tnode_Array (Tnodes.Table (Atype + 1)).Index_Type;
   end Get_Type_Ucarray_Index;

   function Get_Type_Ucarray_Element (Atype : O_Tnode) return O_Tnode is
   begin
      return To_Tnode_Array (Tnodes.Table (Atype + 1)).Element_Type;
   end Get_Type_Ucarray_Element;


   function To_Tnode_Subarray is new Ada.Unchecked_Conversion
     (Source => Tnode_Common, Target => Tnode_Subarray);

   function Get_Type_Subarray_Base (Atype : O_Tnode) return O_Tnode is
   begin
      return To_Tnode_Subarray (Tnodes.Table (Atype + 1)).Base_Type;
   end Get_Type_Subarray_Base;

   function Get_Type_Subarray_Length (Atype : O_Tnode) return Uns32 is
   begin
      return To_Tnode_Subarray (Tnodes.Table (Atype + 1)).Length;
   end Get_Type_Subarray_Length;


   function To_Tnode_Record is new Ada.Unchecked_Conversion
     (Source => Tnode_Common, Target => Tnode_Record);

   function Get_Type_Record_Fields (Atype : O_Tnode) return O_Fnode is
   begin
      return To_Tnode_Record (Tnodes.Table (Atype + 1)).Fields;
   end Get_Type_Record_Fields;

   function Get_Type_Record_Nbr_Fields (Atype : O_Tnode) return Uns32 is
   begin
      return To_Tnode_Record (Tnodes.Table (Atype + 1)).Nbr_Fields;
   end Get_Type_Record_Nbr_Fields;

   function To_Tnode_Enum is new Ada.Unchecked_Conversion
     (Source => Tnode_Common, Target => Tnode_Enum);

   function Get_Type_Enum_Lits (Atype : O_Tnode) return O_Cnode is
   begin
      return To_Tnode_Enum (Tnodes.Table (Atype + 1)).Lits;
   end Get_Type_Enum_Lits;

   function Get_Type_Enum_Lit (Atype : O_Tnode; Pos : Uns32) return O_Cnode
   is
      F : O_Cnode;
   begin
      F := Get_Type_Enum_Lits (Atype);
      return F + 2 * O_Cnode (Pos);
   end Get_Type_Enum_Lit;

   function Get_Type_Enum_Nbr_Lits (Atype : O_Tnode) return Uns32 is
   begin
      return To_Tnode_Enum (Tnodes.Table (Atype + 1)).Nbr_Lits;
   end Get_Type_Enum_Nbr_Lits;


   function To_Tnode_Bool is new Ada.Unchecked_Conversion
     (Source => Tnode_Common, Target => Tnode_Bool);

   function Get_Type_Bool_False (Atype : O_Tnode) return O_Cnode is
   begin
      return To_Tnode_Bool (Tnodes.Table (Atype + 1)).Lit_False;
   end Get_Type_Bool_False;

   function Get_Type_Bool_True (Atype : O_Tnode) return O_Cnode is
   begin
      return To_Tnode_Bool (Tnodes.Table (Atype + 1)).Lit_True;
   end Get_Type_Bool_True;

   function Get_Field_Offset (Field : O_Fnode) return Uns32 is
   begin
      return Fnodes.Table (Field).Offset;
   end Get_Field_Offset;

   function Get_Field_Type (Field : O_Fnode) return O_Tnode is
   begin
      return Fnodes.Table (Field).Ftype;
   end Get_Field_Type;

   function Get_Field_Ident (Field : O_Fnode) return O_Ident is
   begin
      return Fnodes.Table (Field).Ident;
   end Get_Field_Ident;

   function Get_Field_Chain (Field : O_Fnode) return O_Fnode is
   begin
      return Field + 1;
   end Get_Field_Chain;

   function New_Unsigned_Type (Size : Natural) return O_Tnode
   is
      Mode : Mode_Type;
      Sz : Uns32;
   begin
      case Size is
         when 8 =>
            Mode := Mode_U8;
            Sz := 1;
         when 16 =>
            Mode := Mode_U16;
            Sz := 2;
         when 32 =>
            Mode := Mode_U32;
            Sz := 4;
         when 64 =>
            Mode := Mode_U64;
            Sz := 8;
         when others =>
            raise Program_Error;
      end case;
      Tnodes.Append (Tnode_Common'(Kind => OT_Unsigned,
                                  Mode => Mode,
                                  Align => Mode_Align (Mode),
                                  Pad0 => (others => False),
                                  Size => Sz));
      return Tnodes.Last;
   end New_Unsigned_Type;

   function New_Signed_Type (Size : Natural) return O_Tnode
   is
      Mode : Mode_Type;
      Sz : Uns32;
   begin
      case Size is
         when 8 =>
            Mode := Mode_I8;
            Sz := 1;
         when 16 =>
            Mode := Mode_I16;
            Sz := 2;
         when 32 =>
            Mode := Mode_I32;
            Sz := 4;
         when 64 =>
            Mode := Mode_I64;
            Sz := 8;
         when others =>
            raise Program_Error;
      end case;
      Tnodes.Append (Tnode_Common'(Kind => OT_Signed,
                                  Mode => Mode,
                                  Align => Mode_Align (Mode),
                                  Pad0 => (others => False),
                                  Size => Sz));
      return Tnodes.Last;
   end New_Signed_Type;

   function New_Float_Type return O_Tnode is
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Float,
                                  Mode => Mode_F64,
                                  Align => Mode_Align (Mode_F64),
                                  Pad0 => (others => False),
                                  Size => 8));
      return Tnodes.Last;
   end New_Float_Type;

   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Enum, Target => Tnode_Common);

   procedure Start_Enum_Type (List : out O_Enum_List; Size : Natural)
   is
      Mode : Mode_Type;
      Sz : Uns32;
   begin
      case Size is
         when 8 =>
            Mode := Mode_U8;
            Sz := 1;
         when 16 =>
            Mode := Mode_U16;
            Sz := 2;
         when 32 =>
            Mode := Mode_U32;
            Sz := 4;
         when 64 =>
            Mode := Mode_U64;
            Sz := 8;
         when others =>
            raise Program_Error;
      end case;
      Tnodes.Append (Tnode_Common'(Kind => OT_Enum,
                                  Mode => Mode,
                                  Align => Mode_Align (Mode),
                                  Pad0 => (others => False),
                                  Size => Sz));
      List := (Res => Tnodes.Last,
               First => O_Cnode_Null,
               Last => O_Cnode_Null,
               Nbr => 0);
      Tnodes.Increment_Last;
   end Start_Enum_Type;

   procedure New_Enum_Literal (List : in out O_Enum_List;
                               Ident : O_Ident; Res : out O_Cnode)
   is
   begin
      Res := New_Named_Literal (List.Res, Ident, List.Nbr, List.Last);
      List.Nbr := List.Nbr + 1;
      if List.Last = O_Cnode_Null then
         List.First := Res;
      end if;
      List.Last := Res;
   end New_Enum_Literal;

   procedure Finish_Enum_Type (List : in out O_Enum_List; Res : out O_Tnode) is
   begin
      Res := List.Res;
      Tnodes.Table (List.Res + 1) := To_Tnode_Common
        (Tnode_Enum'(Lits => List.First,
                     Nbr_Lits => List.Nbr));
   end Finish_Enum_Type;


   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Bool, Target => Tnode_Common);

   procedure New_Boolean_Type (Res : out O_Tnode;
                               False_Id : O_Ident;
                               False_E : out O_Cnode;
                               True_Id : O_Ident;
                               True_E : out O_Cnode)
   is
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Boolean,
                                  Mode => Mode_B2,
                                  Align => 0,
                                  Pad0 => (others => False),
                                  Size => 1));
      Res := Tnodes.Last;
      False_E := New_Named_Literal (Res, False_Id, 0, O_Cnode_Null);
      True_E := New_Named_Literal (Res, True_Id, 1, False_E);
      Tnodes.Append (To_Tnode_Common (Tnode_Bool'(Lit_False => False_E,
                                                 Lit_True => True_E)));
   end New_Boolean_Type;

   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Array, Target => Tnode_Common);

   function New_Array_Type (El_Type : O_Tnode; Index_Type : O_Tnode)
                           return O_Tnode
   is
      Res : O_Tnode;
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Ucarray,
                                  Mode => Mode_Blk,
                                  Align => Get_Type_Align (El_Type),
                                  Pad0 => (others => False),
                                  Size => 0));
      Res := Tnodes.Last;
      Tnodes.Append (To_Tnode_Common (Tnode_Array'(Element_Type => El_Type,
                                                  Index_Type => Index_Type)));
      return Res;
   end New_Array_Type;

   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Subarray, Target => Tnode_Common);

   function New_Constrained_Array_Type (Atype : O_Tnode; Length : Uns32)
                                       return O_Tnode
   is
      Res : O_Tnode;
      Size : Uns32;
   begin
      Size := Get_Type_Size (Get_Type_Array_Element (Atype));
      Tnodes.Append (Tnode_Common'(Kind => OT_Subarray,
                                  Mode => Mode_Blk,
                                  Align => Get_Type_Align (Atype),
                                  Pad0 => (others => False),
                                  Size => Size * Length));
      Res := Tnodes.Last;
      Tnodes.Append (To_Tnode_Common (Tnode_Subarray'(Base_Type => Atype,
                                                     Length => Length)));
      return Res;
   end New_Constrained_Array_Type;

   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Access, Target => Tnode_Common);

   function New_Access_Type (Dtype : O_Tnode) return O_Tnode
   is
      Res : O_Tnode;
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Access,
                                  Mode => Mode_P32,
                                  Align => Mode_Align (Mode_P32),
                                  Pad0 => (others => False),
                                  Size => 4));
      Res := Tnodes.Last;
      Tnodes.Append (To_Tnode_Common (Tnode_Access'(Dtype => Dtype,
                                                   Pad => 0)));
      return Res;
   end New_Access_Type;

   procedure Finish_Access_Type (Atype : O_Tnode; Dtype : O_Tnode) is
   begin
      if Get_Type_Access_Type (Atype) /= O_Tnode_Null then
         raise Program_Error;
      end if;
      Tnodes.Table (Atype + 1) :=
        To_Tnode_Common (Tnode_Access'(Dtype => Dtype,
                                       Pad => 0));
   end Finish_Access_Type;


   function To_Tnode_Common is new Ada.Unchecked_Conversion
     (Source => Tnode_Record, Target => Tnode_Common);

   function Create_Record_Type return O_Tnode
   is
      Res : O_Tnode;
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Record,
                                  Mode => Mode_Blk,
                                  Align => 0,
                                  Pad0 => (others => False),
                                  Size => 0));
      Res := Tnodes.Last;
      Tnodes.Append (To_Tnode_Common (Tnode_Record'(Fields => O_Fnode_Null,
                                                   Nbr_Fields => 0)));
      return Res;
   end Create_Record_Type;

   procedure Start_Record_Type (Elements : out O_Element_List)
   is
   begin
      Elements := (Res => Create_Record_Type,
                   First_Field => O_Fnode_Null,
                   Last_Field => O_Fnode_Null,
                   Off => 0,
                   Align => 0,
                   Nbr => 0);
   end Start_Record_Type;

   procedure New_Uncomplete_Record_Type (Res : out O_Tnode) is
   begin
      Res := Create_Record_Type;
   end New_Uncomplete_Record_Type;

   procedure Start_Uncomplete_Record_Type (Res : O_Tnode;
                                           Elements : out O_Element_List)
   is
   begin
      Elements := (Res => Res,
                   First_Field => O_Fnode_Null,
                   Last_Field => O_Fnode_Null,
                   Off => 0,
                   Align => 0,
                   Nbr => 0);
   end Start_Uncomplete_Record_Type;

   function Get_Mode_Size (Mode : Mode_Type) return Uns32 is
   begin
      case Mode is
         when Mode_B2
           | Mode_U8
           | Mode_I8 =>
            return 1;
         when Mode_I16
           | Mode_U16 =>
            return 2;
         when Mode_I32
           | Mode_U32
           | Mode_P32
           | Mode_F32 =>
            return 4;
         when Mode_I64
           | Mode_U64
           | Mode_P64
           | Mode_F64 =>
            return 8;
         when Mode_X1
           | Mode_Nil
           | Mode_Blk =>
            raise Program_Error;
      end case;
   end Get_Mode_Size;

   function Do_Align (Off : Uns32; Atype : O_Tnode) return Uns32
   is
      Msk : Uns32;
   begin
      --  Align.
      Msk := Get_Type_Align_Byte (Atype) - 1;
      return (Off + Msk) and (not Msk);
   end Do_Align;

   function Do_Align (Off : Uns32; Mode : Mode_Type) return Uns32
   is
      Msk : Uns32;
   begin
      --  Align.
      Msk := Get_Mode_Size (Mode) - 1;
      return (Off + Msk) and (not Msk);
   end Do_Align;

   procedure New_Record_Field
     (Elements : in out O_Element_List;
      El : out O_Fnode;
      Ident : O_Ident;
      Etype : O_Tnode)
   is
   begin
      Elements.Off := Do_Align (Elements.Off, Etype);

      Fnodes.Append (Field_Type'(Ident => Ident,
                                 Ftype => Etype,
                                 Offset => Elements.Off,
                                 Next => O_Fnode_Null));
      El := Fnodes.Last;
      Elements.Off := Elements.Off + Get_Type_Size (Etype);
      if Get_Type_Align (Etype) > Elements.Align then
         Elements.Align := Get_Type_Align (Etype);
      end if;
      if Elements.Last_Field /= O_Fnode_Null then
         Fnodes.Table (Elements.Last_Field).Next := Fnodes.Last;
      else
         Elements.First_Field := Fnodes.Last;
      end if;
      Elements.Last_Field := Fnodes.Last;
      Elements.Nbr := Elements.Nbr + 1;
   end New_Record_Field;

   procedure Finish_Record_Type
     (Elements : in out O_Element_List; Res : out O_Tnode)
   is
   begin
      Tnodes.Table (Elements.Res).Size := Do_Align (Elements.Off,
                                                    Elements.Res);
      Tnodes.Table (Elements.Res).Align := Elements.Align;
      Tnodes.Table (Elements.Res + 1) := To_Tnode_Common
        (Tnode_Record'(Fields => Elements.First_Field,
                       Nbr_Fields => Elements.Nbr));
      Res := Elements.Res;
   end Finish_Record_Type;

   procedure Start_Union_Type (Elements : out O_Element_List)
   is
   begin
      Tnodes.Append (Tnode_Common'(Kind => OT_Union,
                                  Mode => Mode_Blk,
                                  Align => 0,
                                  Pad0 => (others => False),
                                  Size => 0));
      Elements := (Res => Tnodes.Last,
                   First_Field => O_Fnode_Null,
                   Last_Field => O_Fnode_Null,
                   Off => 0,
                   Align => 0,
                   Nbr => 0);
      Tnodes.Append (To_Tnode_Common (Tnode_Record'(Fields => O_Fnode_Null,
                                                   Nbr_Fields => 0)));
   end Start_Union_Type;

   procedure New_Union_Field
     (Elements : in out O_Element_List;
      El : out O_Fnode;
      Ident : O_Ident;
      Etype : O_Tnode)
   is
      Off : Uns32;
   begin
      Off := Elements.Off;
      Elements.Off := 0;
      New_Record_Field (Elements, El, Ident, Etype);
      if Off > Elements.Off then
         Elements.Off := Off;
      end if;
   end New_Union_Field;

   procedure Finish_Union_Type
     (Elements : in out O_Element_List; Res : out O_Tnode)
   is
   begin
      Finish_Record_Type (Elements, Res);
   end Finish_Union_Type;

   function Get_Type_Array_Element (Atype : O_Tnode) return O_Tnode
   is
      Base : O_Tnode;
   begin
      case Get_Type_Kind (Atype) is
         when OT_Ucarray =>
            Base := Atype;
         when OT_Subarray =>
            Base := Get_Type_Subarray_Base (Atype);
         when others =>
            raise Program_Error;
      end case;
      return Get_Type_Ucarray_Element (Base);
   end Get_Type_Array_Element;

   procedure Disp_Type (Atype : O_Tnode)
   is
      use Ortho_Code.Debug.Int32_IO;
      use Ada.Text_IO;
      Kind : OT_Kind;
   begin
      Put (Int32 (Atype), 3);
      Put (" ");
      Kind := Get_Type_Kind (Atype);
      Put (OT_Kind'Image (Get_Type_Kind (Atype)));
      Put ("  ");
      Put (Mode_Type'Image (Get_Type_Mode (Atype)));
      New_Line;
      case Kind is
         when OT_Boolean =>
            Put ("  false: ");
            Put (Int32 (Get_Type_Bool_False (Atype)));
            Put (", true: ");
            Put (Int32 (Get_Type_Bool_True (Atype)));
            New_Line;
         when others =>
            null;
      end case;
   end Disp_Type;
   pragma Unreferenced (Disp_Type);

   procedure Mark (M : out Mark_Type) is
   begin
      M.Tnode := Tnodes.Last;
      M.Fnode := Fnodes.Last;
   end Mark;

   procedure Release (M : Mark_Type) is
   begin
      Tnodes.Set_Last (M.Tnode);
      Fnodes.Set_Last (M.Fnode);
   end Release;

   procedure Disp_Stats
   is
      use Ada.Text_IO;
   begin
      Put_Line ("Number of Tnodes: " & O_Tnode'Image (Tnodes.Last));
      Put_Line ("Number of Fnodes: " & O_Fnode'Image (Fnodes.Last));
   end Disp_Stats;

   procedure Finish is
   begin
      Tnodes.Free;
      Fnodes.Free;
   end Finish;
end Ortho_Code.Types;