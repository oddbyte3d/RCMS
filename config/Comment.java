/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.cuppait.cuppaweb.workflow;

import com.cuppait.cuppaweb.user.CuppaUser;
import java.util.Date;

/**
 *
 * @author staylor
 */
public class Comment implements java.io.Serializable
{

    private CuppaUser submitter;
    private String comment;
    private Date dateSubmitted;

    public Comment(CuppaUser submitter, String comment) {
        this.submitter = submitter;
        this.comment = comment;
        this.dateSubmitted = new Date();
    }

    public Date getSubmissionDate()
    {
        return this.dateSubmitted;
    }

    public String getComment() {
        return comment;
    }

    public CuppaUser getSubmitter() {
        return submitter;
    }

    

}
