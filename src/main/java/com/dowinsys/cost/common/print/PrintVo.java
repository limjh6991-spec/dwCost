package com.dowinsys.cost.common.print;

import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Setter
@Getter
@NoArgsConstructor
public class PrintVo {
	private List<String> zplList;
	private String printerIp;
	private int printerPort;
}
