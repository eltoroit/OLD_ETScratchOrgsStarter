import { LightningElement } from "lwc";

export default class DemoCounter extends LightningElement {
	counter = 0;
	errorCount = 0;

	plus1() {
		this.counter++;
		this.errorCount = 0;
	}

	updateCounter(event) {
		const value = event.target.value;
		if (isNaN(value)) {
			this.counter = 0;
			this.errorCount++;
			this.template.querySelector("lightning-input").value = this.counter;
		} else {
			this.counter = value;
			this.errorCount = 0;
		}
	}
}
