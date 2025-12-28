package com.xcm;

import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.ScriptPack;
import com.jpexs.decompiler.flash.abc.avm2.AVM2ConstantPool;
import com.jpexs.decompiler.flash.abc.types.ClassInfo;
import com.jpexs.decompiler.flash.abc.types.InstanceInfo;
import com.jpexs.decompiler.flash.abc.types.MethodBody;
import com.jpexs.decompiler.flash.abc.types.traits.TraitClass;
import com.jpexs.decompiler.flash.abc.types.traits.Traits;
import com.jpexs.decompiler.flash.tags.ABCContainerTag;
import com.jpexs.decompiler.flash.tags.Tag;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("用法: java -jar swfUtils.jar <输入文件> <输出文件>");
            System.err.println("示例: java -jar swfUtils.jar input.swf output.swf");
            System.exit(1);
            return;
        }

        String inputFile = args[0];
        String outputFile = args[1];

        System.out.println("开始处理文件: " + inputFile);
        System.out.println("输出文件到: " + outputFile);

        try (FileInputStream fis = new FileInputStream(inputFile)) {
            SWF swf = new SWF(fis, true);
            removeSecurity(swf);

            try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                swf.saveTo(fos);
                System.out.println("处理完成!");
            }
        } catch (IOException e) {
            System.err.println("IO错误: " + e.getMessage());
            System.exit(2);
        } catch (InterruptedException e) {
            System.err.println("操作被中断: " + e.getMessage());
            System.exit(3);
        } catch (Exception e) {
            System.err.println("处理过程中发生未知错误: " + e.getMessage());
            System.exit(4);
        }
    }

    public static void removeSecurity(SWF swf) throws InterruptedException {
        for (ABCContainerTag abcTag : swf.getAbcList()) {
            ABC abc = abcTag.getABC();
            AVM2ConstantPool constants = abc.constants;

            for (int i = 1; i < constants.getStringCount(); i++) {
                String originalStr = constants.getString(i);
                if (originalStr == null) {
                    continue;
                }

                String replacedStr = switch (originalStr) {
                    case "URLLoader" -> "XCMURLLoader";
                    case "Security" -> "XCMSecurity";
                    case "Loader" -> "XCMLoader";
                    default -> originalStr;
                };

                if (!replacedStr.equals(originalStr)) {
                    constants.setString(i, replacedStr);
                }
            }

            if (abcTag instanceof Tag) {
                ((Tag) abcTag).setModified(true);
            }
        }
    }
}