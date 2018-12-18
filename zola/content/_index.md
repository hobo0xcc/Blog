+++
title = "Hobo's computer blog"
sort_by = "date"
render = true
+++

{% for post in section pages %}
	<h1><a href="{{ post.permalink }}">{{ post.title }}</a></h1>
{% endfor %}
