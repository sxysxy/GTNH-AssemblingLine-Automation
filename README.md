# GTNH-AssemblingLine-Automation

[中文版](./README_zh.md)

Fully automation of assembling line in GTNH powered by OpenComputers. **Throw alawys that stupid database!**

- **Features:**
- 1.  Automation for all assembling line recipes. There's no need to manually build a database. You can just make an ME template and then request to craft it.
- 2.  Do not require a renaming trick to solve stacking conflict. Some recipe, for example, heavy alloy Ingot T4, or Fusion Reactor Computers, the have unfully stacked input items, which makes it hard to precisely dispatch the materials to the assembling line. This issue was sovled by renaming trick. (See pure AE automation on assebling line) But my system does not require renaming. You can just directly send the original materials.
- 3. Fast scheduling: Previous automation work for assembling line by OC use transposers or robots to transfer the items from the input chest to the input buses. They bring high latency. My system make use of a local AE system, it uses OC to control the ME output bus to send the materials. What's more, The items without stacking issues could be parallelly sent to the assembling line, only those with stacking issues will be sent sequentially. And when the assembling line starts to craft, the OC system could immediately accept the next crafting request and dispatch the materials. of the next recipe, making a pipelined work. This accelerates the system further. 
- 4. Data Sticks could be automated. You can add the data stick of the output item, in the last slot of its ME template. If a recipe is sent with a  encoded data stick, the OC system could insert  the data stick into the data access hatch and remove it after finished.
- 5. One computer could manage many assembling lines, as long as the computer could connect the component.
- **Disadvantages:** It requires to configure many address and directions in configuration file. Some understanding of oc and basic lua syntax is required