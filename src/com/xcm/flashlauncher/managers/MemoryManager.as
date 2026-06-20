package com.xcm.flashlauncher.managers {

import flash.display.Sprite;
import flash.display.Stage;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.system.System;

/**
 * 内存显示管理器
 */
public class MemoryManager {

    private var stage:Stage;

    // 容纳内存显示背景和文本的容器
    private var memoryContainer:Sprite;

    // 显示内存数值的文本框
    private var memoryField:TextField;

    // 内存显示的背景
    private var memoryBackground:Sprite;

    // 定时器，每5秒更新一次内存数值
    private var memoryTimer:Timer;

    private var isVisible:Boolean = false;

    // 父容器引用，内存容器将被添加到此容器中
    private var parentContainer:Sprite;

    /**
     * 构造函数
     * 初始化内存容器和定时器，并为定时器添加监听。
     */
    public function MemoryManager() {
        memoryContainer = new Sprite();
        memoryTimer = new Timer(5000, 0);
        memoryTimer.addEventListener(TimerEvent.TIMER, updateMemory);
    }

    /**
     * 设置舞台引用（预留，供后续可能需要访问舞台的方法使用）
     * @param stage 舞台对象
     */
    public function setStage(stage:Stage):void {
        this.stage = stage;
    }

    /**
     * 设置父容器，内存显示将添加到此容器中
     * @param container 父容器
     */
    public function setParentContainer(container:Sprite):void {
        this.parentContainer = container;
    }

    /**
     * 获取内存容器
     * @return 内存容器 Sprite
     */
    public function getMemoryContainer():Sprite {
        return memoryContainer;
    }

    /**
     * 确保内存容器位于父容器的最上层
     * 仅在 memoryContainer 确实属于 parentContainer 时尝试调整层级
     */
    public function ensureTopLayer():void {
        if (parentContainer && memoryContainer.parent == parentContainer) {
            try {
                // 将 memoryContainer 移动到父容器的最后一个子索引（即最上层）
                parentContainer.setChildIndex(memoryContainer, parentContainer.numChildren - 1);
            } catch (error:Error) {
                // 忽略可能出现的错误（例如容器不在列表中）
                trace("调整层级失败: " + error.message);
            }
        }
    }

    /**
     * 显示内存显示组件
     * 如果已经显示，则更新位置并确保顶层；否则创建组件并添加到父容器。
     */
    public function showMemoryDisplay():void {
        // 情况1：已经显示并且容器有父级（正常状态），只需更新位置和层级
        if (isVisible && memoryContainer.parent) {
            memoryContainer.x = 10;
            memoryContainer.y = 10;
            ensureTopLayer();
            return;
        }

        // 情况2：标记为可见但父容器丢失（异常，例如父容器被销毁），重新添加到父容器
        if (isVisible && !memoryContainer.parent && parentContainer) {
            parentContainer.addChild(memoryContainer);
            memoryContainer.x = 10;
            memoryContainer.y = 10;
            ensureTopLayer();
            return;
        }

        // 情况3：首次显示或需要重建（清除旧内容，重新创建背景和文本）
        while (memoryContainer.numChildren > 0) {
            memoryContainer.removeChildAt(0);
        }

        // 创建背景（半透明黑色，带绿色边框）
        memoryBackground = new Sprite();
        memoryBackground.graphics.beginFill(0x000000, 0.7);
        memoryBackground.graphics.drawRect(0, 0, 120, 24);
        memoryBackground.graphics.endFill();
        memoryBackground.graphics.lineStyle(1, 0x00FF00, 0.5);
        memoryBackground.graphics.drawRect(0, 0, 120, 24);

        // 创建文本
        memoryField = new TextField();
        memoryField.defaultTextFormat = new TextFormat("_sans", 12, 0x00FF00, true);
        memoryField.autoSize = "left";
        memoryField.selectable = false;
        memoryField.mouseEnabled = false;
        memoryField.text = "内存: 0 MB";
        memoryField.x = 8;
        memoryField.y = 4;

        // 将背景和文本添加到内存容器
        memoryContainer.addChild(memoryBackground);
        memoryContainer.addChild(memoryField);

        // 设置内存容器在舞台上的初始位置（左上角）
        memoryContainer.x = 10;
        memoryContainer.y = 10;

        // 将内存容器添加到指定的父容器
        if (parentContainer) {
            parentContainer.addChild(memoryContainer);
        }

        // 确保容器在父容器的最上层
        ensureTopLayer();

        // 启动定时器（如果尚未运行）
        if (!memoryTimer.running) {
            memoryTimer.start();
        }

        // 标记为可见
        isVisible = true;

        // 立即更新一次内存数值
        updateMemory(null);
    }

    /**
     * 隐藏内存显示组件
     * 从父容器移除内存容器，并停止定时器。
     */
    public function hideMemoryDisplay():void {
        if (memoryContainer && memoryContainer.parent) {
            memoryContainer.parent.removeChild(memoryContainer);
        }
        if (memoryTimer && memoryTimer.running) {
            memoryTimer.stop();
        }
        isVisible = false;
    }

    /**
     * 切换内存显示的显示/隐藏状态
     */
    public function toggleMemoryDisplay():void {
        if (isVisible) {
            hideMemoryDisplay();
        } else {
            showMemoryDisplay();
        }
    }

    /**
     * 设置内存显示的位置（相对于父容器）
     * @param x 水平坐标
     * @param y 垂直坐标
     */
    public function setPosition(x:Number, y:Number):void {
        memoryContainer.x = x;
        memoryContainer.y = y;
    }

    /**
     * 定时更新内存数值，并根据内存占用改变文本颜色
     * @param e 定时器事件
     */
    private function updateMemory(e:TimerEvent):void {
        // 仅当内存容器仍在显示列表中时才更新
        if (memoryField && memoryContainer && memoryContainer.parent) {
            // 获取当前内存占用（单位：MB），保留两位小数
            var memoryMB:Number = Number((System.privateMemory / 1048576).toFixed(2));
            memoryField.text = "内存: " + memoryMB + " MB";

            // 根据内存大小改变颜色：<100MB绿色，100-300MB黄色，>300MB红色
            if (memoryMB < 100) {
                memoryField.textColor = 0x00FF00;
            } else if (memoryMB < 300) {
                memoryField.textColor = 0xFFFF00;
            } else {
                memoryField.textColor = 0xFF0000;
            }

            // 每次更新时都尝试将其置顶，防止被其他动态添加的内容覆盖
            ensureTopLayer();
        }
    }

    /**
     * 获取当前显示状态
     * @return 是否可见
     */
    public function isMemoryDisplayVisible():Boolean {
        return isVisible;
    }

    /**
     * 释放资源（隐藏显示，移除定时器监听）
     * 在不需要 MemoryManager 时调用，避免内存泄漏
     */
    public function dispose():void {
        hideMemoryDisplay();
        if (memoryTimer) {
            memoryTimer.removeEventListener(TimerEvent.TIMER, updateMemory);
            memoryTimer = null;
        }
    }
}
}