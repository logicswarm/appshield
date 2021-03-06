# @title: Specific capabilities added
# @description: According to pod security standard "Capabilities", capabilities beyond the default set must not be added.
# @recommended_actions: Do not set spec.containers[*].securityContext.capabilities.add and spec.initContainers[*].securityContext.capabilities.add..
# @severity: Medium
# @id: KSV022
# @links: 

package main

import data.lib.kubernetes

default failAdditionalCaps = false

# Add allowed capabilities to this set
allowed_caps = set()

# getContainersWithDisallowedCaps returns a list of containers which have
# additional capabilities not included in the allowed capabilities list
getContainersWithDisallowedCaps[container] {
  allContainers := kubernetes.containers[_]
  set_caps := {cap | cap := allContainers.securityContext.capabilities.add[_]}
  caps_not_allowed := set_caps - allowed_caps
  count(caps_not_allowed) > 0
  container := allContainers.name
}

# cap_msg is a string of allowed capabilities to be print as part of deny message
caps_msg = "" {
  count(allowed_caps) == 0
} else = msg {
  msg := sprintf(" or set it to the following allowed values: %s", [concat(", ", allowed_caps)])
}

# failAdditionalCaps is true if there are containers which set additional capabiliites
# not included in the allowed capabilities list
failAdditionalCaps {
  count(getContainersWithDisallowedCaps) > 0
}

deny[msg] {
  failAdditionalCaps

  msg := sprintf("container %s of %s %s in %s namespace should not set securityContext.capabilities.add%s", 
    [getContainersWithDisallowedCaps[_], lower(kubernetes.kind), kubernetes.name, kubernetes.namespace, caps_msg])
}
